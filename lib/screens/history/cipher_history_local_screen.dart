import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/history_item.dart';
import '../../models/firestore_history_item.dart';
import '../../services/history_service.dart';
import '../../services/firestore_service.dart';
import '../../logic/caesar_logic.dart';
import '../../logic/playfair_logic.dart';

class CipherHistoryLocalScreen extends StatefulWidget {
  const CipherHistoryLocalScreen({super.key});

  @override
  State<CipherHistoryLocalScreen> createState() => _CipherHistoryLocalScreenState();
}

class _CipherHistoryLocalScreenState extends State<CipherHistoryLocalScreen>
    with SingleTickerProviderStateMixin {
  final HistoryService _historyService = HistoryService();
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _fadeController.forward();
    _historyService.loadHistory();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all history items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _historyService.clearHistory();
      await _firestoreService.clearHistory();
      setState(() {});
      _showSnackBar('All history cleared from local and cloud');
    }
  }
  
  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Item'),
        content: const Text('Are you sure you want to delete this cipher history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Get the item before deleting
      final itemToDelete = _historyService.getItem(id);
      
      await _historyService.removeItem(id);
      
      // Find and delete from Firestore by matching properties
      if (itemToDelete != null) {
        try {
          final firestoreItems = await _firestoreService.getHistory();
          final matchingItem = firestoreItems.where((fsItem) =>
            fsItem.cipherType == itemToDelete.cipherName &&
            fsItem.inputText == itemToDelete.inputText &&
            fsItem.outputText == itemToDelete.outputText
          ).firstOrNull;
          
          if (matchingItem != null && matchingItem.id != null) {
            await _firestoreService.deleteHistory(matchingItem.id!);
          }
        } catch (e) {
          print('Error deleting from Firestore: $e');
        }
      }
      
      setState(() {});
      _showSnackBar('Item deleted from local and cloud');
    }
  }
  
  Future<void> _editItem(HistoryItem item) async {
    final TextEditingController inputController = TextEditingController(text: item.inputText);
    final TextEditingController keyController = TextEditingController(text: item.keyOrShift);
    String operationType = item.operationType;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${item.cipherName} Cipher'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operation Type',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Encrypt'),
                        value: 'Encrypt',
                        groupValue: operationType,
                        onChanged: (value) => setState(() => operationType = value!),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Decrypt'),
                        value: 'Decrypt',
                        groupValue: operationType,
                        onChanged: (value) => setState(() => operationType = value!),
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: inputController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Input Text',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: item.cipherName == 'Caesar' ? 'Shift Value' : 'Key',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'input': inputController.text,
                  'key': keyController.text,
                  'operation': operationType,
                });
              },
              child: const Text('Recalculate'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      String newOutput = '';
      bool isEncrypt = result['operation'] == 'Encrypt';
      
      if (item.cipherName == 'Caesar') {
        int shift = int.tryParse(result['key']) ?? 3;
        newOutput = isEncrypt
            ? CaesarLogic.encrypt(result['input'], shift)
            : CaesarLogic.decrypt(result['input'], shift);
      } else if (item.cipherName == 'Playfair') {
        String preparedText = PlayfairLogic.preparePlaintext(result['input']);
        List<List<String>> matrix = PlayfairLogic.generateMatrix(result['key']);
        StringBuffer output = StringBuffer();
        
        for (int i = 0; i < preparedText.length; i += 2) {
          String digraph = preparedText.substring(i, i + 2);
          var processed = isEncrypt
              ? PlayfairLogic.encryptDigraph(digraph, matrix)
              : PlayfairLogic.decryptDigraph(digraph, matrix);
          output.write(isEncrypt ? processed['encrypted'] : processed['decrypted']);
        }
        newOutput = output.toString();
      }
      
      // Update history item
      final updatedItem = HistoryItem(
        id: item.id,
        cipherName: item.cipherName,
        inputText: result['input'],
        outputText: newOutput,
        keyOrShift: result['key'],
        operationType: result['operation'],
        timestamp: DateTime.now(),
      );
      
      await _historyService.removeItem(item.id);
      await _historyService.addItem(updatedItem);
      
      // Find and update in Firestore
      try {
        final firestoreItems = await _firestoreService.getHistory();
        final matchingItem = firestoreItems.where((fsItem) =>
          fsItem.cipherType == item.cipherName &&
          fsItem.inputText == item.inputText &&
          fsItem.outputText == item.outputText
        ).firstOrNull;
        
        if (matchingItem != null && matchingItem.id != null) {
          final firestoreItem = FirestoreHistoryItem(
            cipherType: item.cipherName,
            action: result['operation'],
            inputText: result['input'],
            outputText: newOutput,
            shift: item.cipherName == 'Caesar' ? int.tryParse(result['key']) : null,
            key: item.cipherName == 'Playfair' ? result['key'] : null,
            steps: [],
          );
          await _firestoreService.updateHistory(matchingItem.id!, firestoreItem);
        }
      } catch (e) {
        print('Error updating Firestore: $e');
      }
      
      setState(() {});
      _showSnackBar('History updated in local and cloud!');
    }
    
    inputController.dispose();
    keyController.dispose();
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showItemDetails(HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              item.cipherName == 'Caesar'
                  ? Icons.rotate_right_outlined
                  : Icons.grid_3x3_outlined,
              color: item.cipherName == 'Caesar'
                  ? AppColors.primary
                  : AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text('${item.cipherName} Cipher'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type:', item.operationType),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow(
                item.cipherName == 'Caesar' ? 'Shift:' : 'Key:',
                item.keyOrShift,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Input:', item.inputText),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Output:', item.outputText),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow(
                'Date:',
                DateFormat('MMM dd, yyyy hh:mm a').format(item.timestamp),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final history = _historyService.history;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cipher History'),
        elevation: 0,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearHistory,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryCard(history[index], index);
                  },
                ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No History Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.grey,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your cipher operations will appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHistoryCard(HistoryItem item, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: InkWell(
          onTap: () => _showItemDetails(item),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cipher badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: item.cipherName == 'Caesar'
                            ? AppColors.primaryLight
                            : AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.cipherName == 'Caesar'
                                ? Icons.rotate_right_outlined
                                : Icons.grid_3x3_outlined,
                            size: 16,
                            color: item.cipherName == 'Caesar'
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            item.cipherName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.cipherName == 'Caesar'
                                  ? AppColors.primary
                                  : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: item.operationType == 'Encrypt'
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            item.operationType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.operationType == 'Encrypt'
                                  ? AppColors.success
                                  : AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.primary,
                          onPressed: () => _editItem(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit and Recalculate',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          onPressed: () => _deleteItem(item.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Input text
                Text(
                  'Input:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.inputText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Output text
                Text(
                  'Output:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.outputText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: item.cipherName == 'Caesar'
                            ? AppColors.primary
                            : AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.cipherName == 'Caesar'
                              ? Icons.fiber_manual_record
                              : Icons.vpn_key,
                          size: 14,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          item.cipherName == 'Caesar'
                              ? 'Shift: ${item.keyOrShift}'
                              : 'Key: ${item.keyOrShift}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey,
                              ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppColors.grey),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(item.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
