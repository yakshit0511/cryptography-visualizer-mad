import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/constants.dart';
import '../../models/firestore_history_item.dart';
import '../../services/firestore_service.dart';
import '../../logic/caesar_logic.dart';
import '../../logic/playfair_logic.dart';

class FirestoreHistoryScreen extends StatefulWidget {
  const FirestoreHistoryScreen({super.key});

  @override
  State<FirestoreHistoryScreen> createState() => _FirestoreHistoryScreenState();
}

class _FirestoreHistoryScreenState extends State<FirestoreHistoryScreen>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all history items? This action cannot be undone.',
        ),
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
      final success = await _firestoreService.clearHistory();
      if (mounted) {
        _showSnackBar(
          success
              ? '✅ All history cleared from cloud'
              : '❌ Failed to clear history',
          isSuccess: success,
        );
      }
    }
  }

  Future<void> _deleteItem(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History Item'),
        content: const Text('Are you sure you want to delete this item?'),
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
      final success = await _firestoreService.deleteHistory(documentId);
      if (mounted) {
        _showSnackBar(
          success ? '✅ Item deleted' : '❌ Failed to delete',
          isSuccess: success,
        );
      }
    }
  }

  Future<void> _editItem(FirestoreHistoryItem item) async {
    final TextEditingController inputController = TextEditingController(text: item.inputText);
    final TextEditingController keyController = TextEditingController(
      text: item.shift?.toString() ?? item.key ?? '',
    );
    String operationType = item.action;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${item.cipherType} Cipher'),
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
                    labelText: item.cipherType == 'Caesar' ? 'Shift Value' : 'Key',
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

      if (item.cipherType == 'Caesar') {
        int shift = int.tryParse(result['key']) ?? 3;
        newOutput = isEncrypt
            ? CaesarLogic.encrypt(result['input'], shift)
            : CaesarLogic.decrypt(result['input'], shift);
      } else if (item.cipherType == 'Playfair') {
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

      // Update Firestore item
      final updatedItem = FirestoreHistoryItem(
        cipherType: item.cipherType,
        action: result['operation'],
        inputText: result['input'],
        outputText: newOutput,
        shift: item.cipherType == 'Caesar' ? int.tryParse(result['key']) : null,
        key: item.cipherType == 'Playfair' ? result['key'] : null,
        steps: [],
      );

      if (item.id != null) {
        final success = await _firestoreService.updateHistory(item.id!, updatedItem);
        if (mounted) {
          _showSnackBar(
            success ? '✅ History updated!' : '❌ Failed to update',
            isSuccess: success,
          );
        }
      }
    }

    inputController.dispose();
    keyController.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: AppColors.white,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  void _showItemDetails(FirestoreHistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              item.cipherType == 'Caesar'
                  ? Icons.rotate_right_outlined
                  : Icons.grid_3x3_outlined,
              color: item.cipherType == 'Caesar'
                  ? AppColors.primary
                  : AppColors.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Text('${item.cipherType} Cipher'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action:', item.action),
              const SizedBox(height: AppSpacing.md),
              if (item.shift != null)
                _buildDetailRow('Shift:', item.shift.toString()),
              if (item.key != null) _buildDetailRow('Key:', item.key!),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Input:', item.inputText),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Output:', item.outputText),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Date:', item.getFormattedDate()),
              if (item.steps.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Transformation Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...item.steps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
              ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.cloud_queue, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Cloud History'),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearAllHistory,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<List<FirestoreHistoryItem>>(
          stream: _firestoreService.getHistoryStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error loading history',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ],
                ),
              );
            }

            final historyItems = snapshot.data ?? [];

            if (historyItems.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(historyItems[index], index);
              },
            );
          },
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
            Icons.cloud_off,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'No Cloud History Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.grey,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your cipher operations will appear here\nwhen you add them to history',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(FirestoreHistoryItem item, int index) {
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
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: item.cipherType == 'Caesar'
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.secondary.withOpacity(0.3),
            width: 1,
          ),
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
                        gradient: item.cipherType == 'Caesar'
                            ? AppGradients.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  AppColors.secondary.withOpacity(0.7),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.cipherType == 'Caesar'
                                ? Icons.rotate_right_outlined
                                : Icons.grid_3x3_outlined,
                            size: 16,
                            color: AppColors.white,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            item.cipherType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
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
                            color: item.action == 'Encrypt'
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            item.action,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: item.action == 'Encrypt'
                                  ? AppColors.success
                                  : AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          color: AppColors.primary,
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: item.outputText));
                            _showSnackBar('📋 Copied to clipboard!',
                                isSuccess: true);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Copy Output',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.secondary,
                          onPressed: () => _editItem(item),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          onPressed: () => _deleteItem(item.id!),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Key/Shift display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    item.cipherType == 'Caesar'
                        ? 'Shift: ${item.shift}'
                        : 'Key: ${item.key}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Input/Output preview
                _buildTextPreview('Input', item.inputText, AppColors.primary),
                const SizedBox(height: AppSpacing.sm),
                _buildTextPreview('Output', item.outputText, AppColors.success),
                const SizedBox(height: AppSpacing.sm),
                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.getFormattedDate(),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.grey,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.cloud_done,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Synced',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildTextPreview(String label, String text, Color color) {
    final displayText =
        text.length > 50 ? '${text.substring(0, 50)}...' : text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            displayText,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
