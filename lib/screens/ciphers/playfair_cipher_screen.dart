import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../config/constants.dart';
import '../../logic/playfair_logic.dart';
import '../../models/history_item.dart';
import '../../models/firestore_history_item.dart';
import '../../services/history_service.dart';
import '../../services/firestore_service.dart';
import '../../services/user_stats_service.dart';

class PlayfairCipherScreen extends StatefulWidget {
  const PlayfairCipherScreen({super.key});

  @override
  State<PlayfairCipherScreen> createState() => _PlayfairCipherScreenState();
}

class _PlayfairCipherScreenState extends State<PlayfairCipherScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final HistoryService _historyService = HistoryService();
  final FirestoreService _firestoreService = FirestoreService();
  final UserStatsService _statsService = UserStatsService();
  
  List<List<String>> _matrix = [];
  String _outputText = '';
  String _operationType = 'Encrypt';
  bool _isProcessing = false;
  bool _showResult = false;
  bool _showAddToHistory = false;
  Set<String> _highlightedCells = {};
  Map<String, Color> _letterColors = {}; // Maps each letter to its color
  List<Map<String, dynamic>> _arrowAnimations = []; // Stores arrow animation data
  
  List<Map<String, dynamic>> _detailedSteps = [];
  int _currentStepIndex = -1;
  
  late AnimationController _fadeController;
  late AnimationController _matrixAnimationController;
  late AnimationController _stepAnimationController;
  late AnimationController _pulseController;
  late AnimationController _arrowAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _matrixFadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _arrowAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _matrixAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _arrowAnimation = CurvedAnimation(
      parent: _arrowAnimationController,
      curve: Curves.easeInOutCubic,
    );
    
    _matrixFadeAnimation = CurvedAnimation(
      parent: _matrixAnimationController,
      curve: Curves.easeInOut,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _historyService.loadHistory();
    _generateMatrix();
  }
  
  @override
  void dispose() {
    _inputController.dispose();
    _keyController.dispose();
    _fadeController.dispose();
    _matrixAnimationController.dispose();
    _stepAnimationController.dispose();
    _pulseController.dispose();
    _arrowAnimationController.dispose();
    super.dispose();
  }
  
  void _generateMatrix() {
    if (_keyController.text.isNotEmpty) {
      setState(() {
        _matrix = PlayfairLogic.generateMatrix(_keyController.text);
      });
      _matrixAnimationController.reset();
      _matrixAnimationController.forward();
    }
  }
  
  Future<void> _processText() async {
    if (_inputController.text.isEmpty) {
      _showSnackBar('Please enter text to process', isError: true);
      return;
    }
    
    if (_keyController.text.isEmpty) {
      _showSnackBar('Please enter a key', isError: true);
      return;
    }
    
    setState(() {
      _isProcessing = true;
      _showResult = false;
      _showAddToHistory = false;
      _detailedSteps = [];
      _currentStepIndex = -1;
      _highlightedCells = {};
      _letterColors = {};
      _arrowAnimations = [];
    });
    
    // Generate matrix if key changed
    _generateMatrix();
    await Future.delayed(const Duration(milliseconds: 500));
    
    bool isEncrypt = _operationType == 'Encrypt';
    
    // Prepare plaintext
    String preparedText = PlayfairLogic.preparePlaintext(_inputController.text);
    
    // Process each digraph with detailed steps
    String result = '';
    List<String> digraphs = [];
    for (int i = 0; i < preparedText.length; i += 2) {
      digraphs.add(preparedText.substring(i, i + 2));
    }
    
    for (int i = 0; i < digraphs.length; i++) {
      String digraph = digraphs[i];
      String processedDigraph;
      Map<String, dynamic> stepDetails;
      
      if (isEncrypt) {
        var encryptResult = PlayfairLogic.encryptDigraph(digraph, _matrix);
        processedDigraph = encryptResult['encrypted'];
        stepDetails = encryptResult;
      } else {
        var decryptResult = PlayfairLogic.decryptDigraph(digraph, _matrix);
        processedDigraph = decryptResult['decrypted'];
        stepDetails = decryptResult;
      }
      
      result += processedDigraph;
      
      // Create detailed step information
      _detailedSteps.add({
        'stepNumber': i + 1,
        'inputDigraph': digraph,
        'outputDigraph': processedDigraph,
        'rule': stepDetails['rule'],
        'explanation': stepDetails['explanation'],
        'highlightCells': stepDetails['highlightCells'],
        'positions': stepDetails['positions'],
      });
    }
    
    setState(() {
      _outputText = result;
      _showResult = true;
    });
    
    // Animate each step slowly
    for (int i = 0; i < _detailedSteps.length; i++) {
      var step = _detailedSteps[i];
      Color stepColor1 = _getStepColor(i * 2);     // First letter color
      Color stepColor2 = _getStepColor(i * 2 + 1); // Second letter color
      String inputDigraph = step['inputDigraph'];
      String outputDigraph = step['outputDigraph'];
      
      // Set DIFFERENT colors for each letter in the digraph
      setState(() {
        _currentStepIndex = i;
        _highlightedCells = Set<String>.from(step['highlightCells']);
        _letterColors = {
          inputDigraph[0]: stepColor1,   // First input letter
          inputDigraph[1]: stepColor2,   // Second input letter
          outputDigraph[0]: stepColor1,  // First output letter (same color as first input)
          outputDigraph[1]: stepColor2,  // Second output letter (same color as second input)
        };
        
        // Create arrow animations for each letter pair with BLACK arrows
        _arrowAnimations = [
          {
            'from': inputDigraph[0],
            'to': outputDigraph[0],
            'color': Colors.black, // BLACK arrow for first letter
            'cellColor': stepColor1, // Keep cell color for highlighting
          },
          {
            'from': inputDigraph[1],
            'to': outputDigraph[1],
            'color': Colors.black, // BLACK arrow for second letter
            'cellColor': stepColor2, // Keep cell color for highlighting
          },
        ];
      });
      
      _stepAnimationController.reset();
      await _stepAnimationController.forward();
      
      // Animate arrows
      _arrowAnimationController.reset();
      await _arrowAnimationController.forward();
      
      // Hold the highlight for a moment
      await Future.delayed(const Duration(milliseconds: 1500));
      
      setState(() {
        _highlightedCells = {};
        _letterColors = {};
        _arrowAnimations = [];
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    // Increment user stats
    await _statsService.incrementCipherCount('Playfair');
    
    setState(() {
      _isProcessing = false;
      _showAddToHistory = true;
      _currentStepIndex = -1;
    });
  }
  
  Future<void> _addToHistory() async {
    if (_outputText.isEmpty) return;
    
    // Show loading indicator
    setState(() => _showAddToHistory = false);
    
    // Save to local history (SharedPreferences)
    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cipherName: 'Playfair',
      inputText: _inputController.text,
      outputText: _outputText,
      keyOrShift: _keyController.text,
      operationType: _operationType,
      timestamp: DateTime.now(),
    );
    await _historyService.addItem(historyItem);
    
    // Prepare step descriptions for Firestore
    List<String> stepDescriptions = _detailedSteps.map((step) {
      return 'Step ${step['stepNumber']}: ${step['inputDigraph']} → ${step['outputDigraph']} [${step['rule']}] - ${step['explanation']}';
    }).toList();
    
    // Save to Firestore
    final firestoreItem = FirestoreHistoryItem(
      cipherType: 'Playfair',
      action: _operationType,
      inputText: _inputController.text,
      outputText: _outputText,
      shift: null,
      key: _keyController.text,
      steps: stepDescriptions,
    );
    
    final success = await _firestoreService.addHistory(firestoreItem);
    
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
        backgroundColor: isSuccess ? AppColors.success : (isError ? AppColors.error : AppColors.secondary),
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
              child: const Icon(Icons.grid_3x3_outlined, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Playfair Cipher'),
          ],
        ),
        backgroundColor: AppColors.secondary,
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
                _buildProcessButton(),
                const SizedBox(height: AppSpacing.xl),
                _buildOperationSelector(),
                const SizedBox(height: AppSpacing.xl),
                _buildMatrixDisplay(),
                if (_detailedSteps.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _buildDetailedStepsDisplay(),
                ],
                if (_showResult) ...[
                  const SizedBox(height: AppSpacing.xxl),
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
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
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
            children: [
              Icon(Icons.vpn_key, color: AppColors.secondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Cipher Key',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _keyController,
            decoration: InputDecoration(
              hintText: 'Enter key (alphabets only)',
              prefixIcon: Icon(Icons.key, color: AppColors.secondary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _generateMatrix,
                color: AppColors.secondary,
                tooltip: 'Regenerate Matrix',
              ),
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
            onChanged: (_) => _generateMatrix(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Matrix updates automatically as you type',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMatrixDisplay() {
    return FadeTransition(
      opacity: _matrixFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_on, color: AppColors.secondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '5×5 Playfair Matrix',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_matrix.isNotEmpty) ...[
              Stack(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 25,
                    itemBuilder: (context, index) {
                  int row = index ~/ 5;
                  int col = index % 5;
                  String letter = _matrix[row][col];
                  String displayLetter = letter == 'I' ? 'I/J' : letter;
                  bool isHighlighted = _highlightedCells.contains(letter);
                  Color? cellColor = _letterColors[letter];
                  
                  return TweenAnimationBuilder<double>(
                    key: ValueKey('$row-$col-${_matrix[row][col]}'),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 100 + (index * 40)),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          decoration: BoxDecoration(
                            gradient: isHighlighted && cellColor != null
                                ? LinearGradient(
                                    colors: [
                                      cellColor,
                                      cellColor.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.secondary.withOpacity(0.7),
                                      AppColors.primary.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: isHighlighted && cellColor != null
                                ? [
                                    BoxShadow(
                                      color: cellColor.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: AppColors.secondary.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: Text(
                              displayLetter,
                              style: TextStyle(
                                fontSize: isHighlighted ? 20 : 16,
                                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                                color: AppColors.white,
                                letterSpacing: letter == 'I' ? 0 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                    },
                  ),
                  // Arrow overlays
                  if (_arrowAnimations.isNotEmpty)
                    ..._arrowAnimations.map((arrowData) {
                      return _buildArrowOverlay(
                        arrowData['from'],
                        arrowData['to'],
                        arrowData['color'],
                      );
                    }).toList(),
                ],
              ),
            ] else ...[
              Text(
                'Enter a key to generate matrix',
                style: TextStyle(
                  color: AppColors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProcessButton() {
    return ElevatedButton(
      onPressed: _isProcessing ? null : _processText,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
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
                  '$_operationType with Playfair',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
  
  Widget _buildDetailedStepsDisplay() {
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _detailedSteps.length,
            itemBuilder: (context, index) {
              var step = _detailedSteps[index];
              bool isCurrent = index == _currentStepIndex;
              
              return TweenAnimationBuilder<double>(
                key: ValueKey(index),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: isCurrent
                              ? LinearGradient(
                                  colors: [
                                    Colors.amber.shade100,
                                    Colors.orange.shade100,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    AppColors.secondary.withOpacity(0.1),
                                    AppColors.primary.withOpacity(0.1),
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.orange
                                : AppColors.secondary.withOpacity(0.3),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    'Step ${step['stepNumber']}',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRuleColor(step['rule']),
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    step['rule'].toString().toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildDigraphBox(
                                  step['inputDigraph'], 
                                  _getStepColor(index),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.secondary,
                                  size: 32,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                _buildDigraphBox(
                                  step['outputDigraph'], 
                                  _getStepColor(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                step['explanation'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
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
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDigraphBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
          letterSpacing: 2,
        ),
      ),
    );
  }
  
  Color _getRuleColor(String rule) {
    switch (rule.toLowerCase()) {
      case 'same row':
        return Colors.blue;
      case 'same column':
        return Colors.green;
      case 'rectangle':
        return Colors.purple;
      default:
        return AppColors.secondary;
    }
  }
  
  Color _getStepColor(int stepIndex) {
    // Generate unique color for each step using a predefined palette
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.purple.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.red.shade600,
      Colors.amber.shade600,
      Colors.cyan.shade600,
      Colors.deepOrange.shade600,
      Colors.deepPurple.shade600,
      Colors.lime.shade700,
      Colors.brown.shade600,
      Colors.blueGrey.shade600,
    ];
    return colors[stepIndex % colors.length];
  }
  
  Widget _buildArrowOverlay(String fromLetter, String toLetter, Color arrowColor) {
    // Find positions of from and to letters in matrix
    Map<String, int>? fromPos;
    Map<String, int>? toPos;
    
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (_matrix[row][col] == fromLetter) {
          fromPos = {'row': row, 'col': col};
        }
        if (_matrix[row][col] == toLetter) {
          toPos = {'row': row, 'col': col};
        }
      }
    }
    
    if (fromPos == null || toPos == null) {
      return const SizedBox.shrink();
    }
    
    // Calculate cell size and spacing
    const double cellSize = 50.0; // Approximate size based on grid
    const double spacing = 8.0;
    const double totalCellSize = cellSize + spacing;
    
    // Calculate center positions
    double fromX = (fromPos['col']! * totalCellSize) + (cellSize / 2);
    double fromY = (fromPos['row']! * totalCellSize) + (cellSize / 2);
    double toX = (toPos['col']! * totalCellSize) + (cellSize / 2);
    double toY = (toPos['row']! * totalCellSize) + (cellSize / 2);
    
    return AnimatedBuilder(
      animation: _arrowAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(totalCellSize * 5, totalCellSize * 5),
          painter: ArrowPainter(
            fromX: fromX,
            fromY: fromY,
            toX: toX,
            toY: toY,
            color: arrowColor, // Use the black arrow color
            progress: _arrowAnimation.value,
          ),
        );
      },
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
}

// Custom painter for drawing animated arrows between matrix cells
class ArrowPainter extends CustomPainter {
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final Color color;
  final double progress;

  ArrowPainter({
    required this.fromX,
    required this.fromY,
    required this.toX,
    required this.toY,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;
    
    // Calculate current end point based on progress
    double currentX = fromX + (toX - fromX) * progress;
    double currentY = fromY + (toY - fromY) * progress;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Draw the arrow line
    canvas.drawLine(
      Offset(fromX, fromY),
      Offset(currentX, currentY),
      paint,
    );
    
    // Draw arrowhead at the end if progress is sufficient
    if (progress > 0.7) {
      final arrowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      // Calculate arrowhead angle
      double angle = math.atan2(toY - fromY, toX - fromX);
      
      const double arrowSize = 10.0;
      const double arrowAngle = math.pi / 6; // 30 degrees
      
      final arrowPath = Path();
      arrowPath.moveTo(currentX, currentY);
      
      // Left side of arrowhead
      arrowPath.lineTo(
        currentX - arrowSize * math.cos(angle - arrowAngle) * (progress - 0.7) / 0.3,
        currentY - arrowSize * math.sin(angle - arrowAngle) * (progress - 0.7) / 0.3,
      );
      
      // Right side of arrowhead
      arrowPath.lineTo(
        currentX - arrowSize * math.cos(angle + arrowAngle) * (progress - 0.7) / 0.3,
        currentY - arrowSize * math.sin(angle + arrowAngle) * (progress - 0.7) / 0.3,
      );
      
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fromX != fromX ||
        oldDelegate.fromY != fromY ||
        oldDelegate.toX != toX ||
        oldDelegate.toY != toY ||
        oldDelegate.color != color;
  }
}
