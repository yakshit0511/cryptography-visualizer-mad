import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../models/cipher_model.dart';
import '../../services/cipher_history_service.dart';

class EditCipherScreen extends StatefulWidget {
  final CipherModel cipher;

  const EditCipherScreen({super.key, required this.cipher});

  @override
  State<EditCipherScreen> createState() => _EditCipherScreenState();
}

class _EditCipherScreenState extends State<EditCipherScreen> {
  final CipherHistoryService _historyService = CipherHistoryService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _inputController;
  late TextEditingController _keyController;
  late TextEditingController _resultController;
  late String _selectedCipherType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: widget.cipher.inputText);
    _keyController = TextEditingController(text: widget.cipher.key);
    _resultController = TextEditingController(text: widget.cipher.resultText);
    _selectedCipherType = widget.cipher.cipherType;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _historyService.updateCipherHistory(
        id: widget.cipher.id,
        inputText: _inputController.text,
        cipherType: _selectedCipherType,
        key: _keyController.text,
        resultText: _resultController.text,
        context: context,
      );

      setState(() => _isLoading = false);

      if (result['success'] && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final responsivePadding = AppResponsivePadding(mediaQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Cipher History'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: responsivePadding.allPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Update your cipher history record',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Cipher Type Dropdown
                Text(
                  'Cipher Type',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _selectedCipherType,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.category),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  items: ['Caesar Cipher', 'Playfair Cipher']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCipherType = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a cipher type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Input Text Field
                Text(
                  'Input Text',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    hintText: 'Enter text to encrypt/decrypt',
                    prefixIcon: const Icon(Icons.input),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Input text cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Key Field
                Text(
                  'Key',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _keyController,
                  decoration: InputDecoration(
                    hintText: 'Enter encryption key',
                    prefixIcon: const Icon(Icons.vpn_key),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Result Text Field
                Text(
                  'Result Text',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _resultController,
                  decoration: InputDecoration(
                    hintText: 'Enter encrypted/decrypted result',
                    prefixIcon: const Icon(Icons.output),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Result text cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Update Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Update History',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Cancel Button
                OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
