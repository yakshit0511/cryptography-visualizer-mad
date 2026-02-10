import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/cipher_model.dart';
import '../../services/cipher_history_service.dart';
import 'edit_cipher_screen.dart';

class CipherHistoryScreen extends StatefulWidget {
  const CipherHistoryScreen({super.key});

  @override
  State<CipherHistoryScreen> createState() => _CipherHistoryScreenState();
}

class _CipherHistoryScreenState extends State<CipherHistoryScreen> {
  final CipherHistoryService _cipherService = CipherHistoryService();

  // Delete confirmation dialog
  Future<void> _showDeleteConfirmation(String id, String cipherType) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete this $cipherType record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCipherRecord(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Delete cipher record
  Future<void> _deleteCipherRecord(String id) async {
    final result = await _cipherService.deleteCipherHistory(
      id: id,
      context: context,
      showConfirmation: false, // We already showed confirmation
    );

    if (mounted && result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Navigate to edit screen
  Future<void> _navigateToEditScreen(CipherModel cipher) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCipherScreen(cipher: cipher),
      ),
    );

    // The list will automatically refresh due to StreamBuilder
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Record updated successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Show cipher details dialog
  void _showCipherDetails(CipherModel cipher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${cipher.cipherType} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type:', cipher.cipherType),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Input Text:', cipher.inputText),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Key:', cipher.key),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow('Result:', cipher.resultText),
              const SizedBox(height: AppSpacing.md),
              _buildDetailRow(
                'Created:',
                cipher.createdAt != null
                    ? DateFormat('MMM dd, yyyy hh:mm a')
                        .format(cipher.createdAt.toDate())
                    : 'N/A',
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
            fontSize: 14,
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
    final mediaQuery = MediaQuery.of(context);
    final responsivePadding = AppResponsivePadding(mediaQuery);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Cipher History'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<CipherModel>>(
          stream: _cipherService.getCipherHistoryStream(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Error loading history',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            // Empty state
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      'Start encrypting text to see your history here',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey,
                          ),
                    ),
                  ],
                ),
              );
            }

            // Data state - Display list of cipher records
            final cipherList = snapshot.data!;

            return Padding(
              padding: responsivePadding.horizontalPadding,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Header with count
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Records: ${cipherList.length}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // List of cipher records
                  Expanded(
                    child: ListView.builder(
                      itemCount: cipherList.length,
                      itemBuilder: (context, index) {
                        final cipher = cipherList[index];
                        return _buildCipherCard(cipher);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCipherCard(CipherModel cipher) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: () => _showCipherDetails(cipher),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with cipher type and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cipher type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: cipher.cipherType == 'Caesar Cipher'
                          ? AppColors.primaryLight
                          : AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      cipher.cipherType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cipher.cipherType == 'Caesar Cipher'
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppColors.secondary,
                        onPressed: () => _navigateToEditScreen(cipher),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        color: AppColors.info,
                        onPressed: () => _showCipherDetails(cipher),
                        tooltip: 'View Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppColors.error,
                        onPressed: () =>
                            _showDeleteConfirmation(cipher.id, cipher.cipherType),
                        tooltip: 'Delete',
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
                cipher.inputText,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              // Result text
              Text(
                'Result:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grey,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                cipher.resultText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              // Footer with key and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.key, size: 14, color: AppColors.grey),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Key: ${cipher.key}',
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
                        cipher.createdAt != null
                            ? DateFormat('MMM dd, hh:mm a')
                                .format(cipher.createdAt.toDate())
                            : 'N/A',
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
    );
  }
}
