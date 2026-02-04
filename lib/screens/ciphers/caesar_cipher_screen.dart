import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/constants.dart';
import '../../logic/caesar_logic.dart';
import '../../models/history_item.dart';
import '../../models/firestore_history_item.dart';
import '../../services/history_service.dart';
import '../../services/user_stats_service.dart';
import '../../providers/cipher_provider.dart';

class CaesarCipherScreen extends StatefulWidget {
  const CaesarCipherScreen({super.key});

  @override
  State<CaesarCipherScreen> createState() => _CaesarCipherScreenState();
}

class _CaesarCipherScreenState extends State<CaesarCipherScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController(text: '3');
  final HistoryService _historyService = HistoryService();
  final UserStatsService _statsService = UserStatsService();
  
  int _shiftValue = 3;
  String _outputText = '';
  String _operationType = 'Encrypt';
  List<Map<String, dynamic>> _transformationSteps = [];
  bool _isProcessing = false;
  bool _showResult = false;
  bool _showAddToHistory = false;
  bool _useSlider = true; // Toggle between slider and keyboard
  
  late AnimationController _buttonAnimationController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _historyService.loadHistory();
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _buttonAnimationController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
  
  Future<void> _processText() async {
    if (_inputController.text.isEmpty) {
      _showSnackBar('Please enter text to process', isError: true);
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _showResult = false;
      _showAddToHistory = false;
      _transformationSteps = [];
    });
    
    // Animate button press
    await _buttonAnimationController.forward();
    await _buttonAnimationController.reverse();
    
    bool isEncrypt = _operationType == 'Encrypt';
    
    // Get transformation steps
    _transformationSteps = CaesarLogic.getStepByStepTransformation(
      _inputController.text,
      _shiftValue,
      isEncrypt,
    );
    
    // Animate each character transformation
    String result = isEncrypt
        ? CaesarLogic.encrypt(_inputController.text, _shiftValue)
        : CaesarLogic.decrypt(_inputController.text, _shiftValue);
    
    setState(() {
      _outputText = result;
      _showResult = true;
    });
    
    // Show transformations sequentially with color animations
    for (int i = 0; i < _transformationSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {});
      }
    }
    
    // Increment user stats
    await _statsService.incrementCipherCount('Caesar');
    
    // Show "Add to History" button after animation completes
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _isProcessing = false;
      _showAddToHistory = true;
    });
  }
  
  Future<void> _addToHistory() async {
    if (_outputText.isEmpty) return;
    
    // Show loading indicator
    setState(() => _showAddToHistory = false);
    
    // Save to local history (SharedPreferences)
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cipherName: 'Caesar',
      inputText: _inputController.text,
      outputText: _outputText,
      keyOrShift: _shiftValue.toString(),
      operationType: _operationType,
      timestamp: DateTime.now(),
    );
    await _historyService.addItem(historyItem);
    
    // Prepare step descriptions for Firestore
    List<String> stepDescriptions = _transformationSteps.map((step) {
      return '${step['original']} → ${step['transformed']} (${step['explanation']})';
    }).toList();
    
    // Save to Firestore
    final firestoreItem = FirestoreHistoryItem(
      cipherType: 'Caesar',
      action: _operationType,
      inputText: _inputController.text,
      outputText: _outputText,
      shift: _shiftValue,
      key: null,
      steps: stepDescriptions,
    );
    
    // Use CipherProvider for automatic UI updates
    final cipherProvider = Provider.of<CipherProvider>(context, listen: false);
    final success = await cipherProvider.addCipher(firestoreItem);
    
    setState(() => _showAddToHistory = true);
    
    if (success) {
      _showSnackBar('✅ Added to History & Saved to Cloud!', isSuccess: true);
    } else {
      _showSnackBar('⚠️ Saved locally, but cloud sync failed', isError: true);
    }
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard!', isSuccess: true);
  }
  
  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
              color: AppColors.white,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : (isError ? AppColors.error : AppColors.primary),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
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
              child: const Icon(Icons.rotate_right_outlined, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Caesar Cipher'),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/cipher_history'),
            tooltip: 'View History',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildKeyInputSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildOperationSelector(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildProcessButton(),
                  if (_showResult) ...[
                    const SizedBox(height: AppSpacing.xxl),

                    _buildTransformationSteps(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildOutputSection(),
                  ],
                  if (_showAddToHistory) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildAddToHistoryButton(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildOperationSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOperationButton('Encrypt', Icons.lock_outline),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildOperationButton('Decrypt', Icons.lock_open_outlined),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOperationButton(String operation, IconData icon) {
    final isSelected = _operationType == operation;
    return GestureDetector(
      onTap: () => setState(() => _operationType = operation),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isSelected ? AppGradients.primaryGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.grey,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              operation,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.input, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Input Text',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _inputController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter text to ${_operationType.toLowerCase()}...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildKeyInputSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.vpn_key, color: AppColors.secondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Shift Key',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _useSlider,
                onChanged: (value) => setState(() => _useSlider = value),
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_useSlider) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _shiftValue.toDouble(),
                    min: -25,
                    max: 25,
                    divisions: 50,
                    activeColor: AppColors.secondary,
                    label: _shiftValue.toString(),
                    onChanged: (value) {
                      setState(() {
                        _shiftValue = value.toInt();
                        _keyController.text = _shiftValue.toString();
                      });
                    },
                  ),
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _shiftValue.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _keyController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter shift value (-25 to 25)',
                prefixIcon: Icon(Icons.keyboard, color: AppColors.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.secondary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: AppColors.secondary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() => _shiftValue = 0);
                  return;
                }
                int? parsed = int.tryParse(value);
                if (parsed != null && parsed >= -25 && parsed <= 25) {
                  setState(() => _shiftValue = parsed);
                }
              },
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            _useSlider ? 'Slide to adjust shift value' : 'Type shift value between -25 and 25',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProcessButton() {
    return ScaleTransition(
      scale: _buttonAnimationController.drive(
        Tween<double>(begin: 1.0, end: 0.95),
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processText,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 4,
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_operationType == 'Encrypt' ? Icons.lock : Icons.lock_open),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _operationType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildOutputSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.output, color: AppColors.success, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Output Text',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () => _copyToClipboard(_outputText),
                        color: AppColors.success,
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: SelectableText(
                      _outputText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTransformationSteps() {
    if (_transformationSteps.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Step-by-Step Transformation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.lg,
            alignment: WrapAlignment.center,
            children: _transformationSteps.asMap().entries.map((entry) {
              int index = entry.key;
              var step = entry.value;
              // Generate unique color for each character
              Color charColor = _getCharacterColor(index);
              return TweenAnimationBuilder<double>(
                key: ValueKey(index),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Original character box
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: charColor,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: charColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              step['original'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          // Black arrow with animation
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 500 + (index * 100)),
                              curve: Curves.easeInOut,
                              builder: (context, arrowValue, child) {
                                return Transform.scale(
                                  scale: arrowValue,
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                );
                              },
                            ),
                          ),
                          // Transformed character box
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: charColor.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: charColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: charColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              step['transformed'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddToHistoryButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: ElevatedButton.icon(
        onPressed: _addToHistory,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          elevation: 4,
        ),
        icon: const Icon(Icons.add_circle_outline),
        label: const Text(
          'Add to History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // Get unique color for each character in Caesar cipher
  Color _getCharacterColor(int index) {
    final colors = [
      Colors.deepPurple.shade600,
      Colors.blue.shade600,
      Colors.teal.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
      Colors.indigo.shade600,
      Colors.red.shade600,
      Colors.amber.shade700,
      Colors.cyan.shade600,
      Colors.lime.shade700,
      Colors.purple.shade600,
      Colors.deepOrange.shade600,
      Colors.blueGrey.shade600,
      Colors.brown.shade600,
    ];
    return colors[index % colors.length];
  }
}
