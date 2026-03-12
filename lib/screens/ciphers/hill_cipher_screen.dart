import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../logic/hill_cipher_logic.dart';
import '../../models/firestore_history_item.dart';
import '../../models/history_item.dart';
import '../../providers/cipher_provider.dart';
import '../../services/history_service.dart';
import '../../services/user_stats_service.dart';
import '../../services/notification_service.dart';

class HillCipherScreen extends StatefulWidget {
  const HillCipherScreen({super.key});

  @override
  State<HillCipherScreen> createState() => _HillCipherScreenState();
}

class _HillCipherScreenState extends State<HillCipherScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keyController = TextEditingController(
    text: 'GYBNQKURP',
  );
  final HistoryService _historyService = HistoryService();
  final UserStatsService _statsService = UserStatsService();

  HillCipherResult? _result;
  String _outputText = '';
  String _operationType = 'Encrypt';
  String? _validationError;
  bool _isDecryptMode = false;
  bool _showAddToHistory = false;

  bool _isAnimating = false;
  bool _isPaused = false;
  int _animationToken = 0;
  double _progress = 0;

  final List<bool> _visibleSections = List<bool>.filled(6, false);
  int _revealedKeyCells = 0;
  int _revealedMessageCells = 0;
  int _activeMultiplicationRow = -1;
  int _activeMultiplicationTerm = -1;
  int _revealedModuloRows = 0;
  int _revealedResultRows = 0;
  int _revealedInverseCells = 0;
  int _inverseDetailStep = 0;
  int _revealedCofactorCells = 0;
  int _revealedAdjugateCells = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _historyService.loadHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _keyController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _encrypt() async {
    await _process(isDecrypt: false);
  }

  Future<void> _decrypt() async {
    await _process(isDecrypt: true);
  }

  Future<void> _process({required bool isDecrypt}) async {
    FocusScope.of(context).unfocus();

    final text = HillCipherLogic.sanitizeAZ(_textController.text);
    final key = HillCipherLogic.sanitizeAZ(_keyController.text);

    final textError = HillCipherLogic.validatePlaintext(text);
    if (textError != null) {
      _showError(
        textError.replaceFirst(
          'Plaintext',
          isDecrypt ? 'Ciphertext' : 'Plaintext',
        ),
      );
      return;
    }

    final keyError = HillCipherLogic.validateKey(key);
    if (keyError != null) {
      _showError(keyError);
      return;
    }

    try {
      final result = isDecrypt
          ? HillCipherLogic.decrypt(ciphertext: text, key: key)
          : HillCipherLogic.encrypt(plaintext: text, key: key);

      setState(() {
        _validationError = null;
        _isDecryptMode = isDecrypt;
        _operationType = isDecrypt ? 'Decrypt' : 'Encrypt';
        _result = result;
        _outputText = result.output;
        _showAddToHistory = false;
      });

      // tell the user we have a result
      NotificationService().showInstantNotification();

      await _startVisualization();
      await _statsService.incrementCipherCount('Hill');

      if (!mounted) return;
      setState(() => _showAddToHistory = true);
    } on FormatException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Unable to process Hill cipher right now.');
    }
  }

  Future<void> _addToHistory() async {
    if (_outputText.isEmpty) return;

    setState(() => _showAddToHistory = false);

    final inputText = HillCipherLogic.sanitizeAZ(_textController.text);
    final key = HillCipherLogic.sanitizeAZ(_keyController.text);
    final safeInput = HillCipherLogic.padToThree(inputText);

    final historyItem = HistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cipherName: 'Hill',
      inputText: safeInput,
      outputText: _outputText,
      keyOrShift: key,
      operationType: _operationType,
      timestamp: DateTime.now(),
    );
    await _historyService.addItem(historyItem);

    final stepData = _result?.steps;
    final stepDescriptions = <String>[];
    if (stepData != null) {
      for (int i = 0; i < 3; i++) {
        stepDescriptions.add(
          'Row ${i + 1}: (${stepData.multiplicationTerms[i].join(' + ')}) = ${stepData.rawProducts[i]} mod 26 = ${stepData.modResults[i]}',
        );
      }
      if (_isDecryptMode && stepData.inverseDetails != null) {
        final inverse = stepData.inverseDetails!;
        stepDescriptions.add(
          'Inverse details: det=${inverse.determinant}, det mod 26=${inverse.determinantMod26}, inv det=${inverse.determinantInverseMod26}',
        );
      }
    }

    final firestoreItem = FirestoreHistoryItem(
      cipherType: 'Hill',
      action: _operationType,
      inputText: safeInput,
      outputText: _outputText,
      shift: null,
      key: key,
      steps: stepDescriptions,
    );

    final cipherProvider = Provider.of<CipherProvider>(context, listen: false);
    final success = await cipherProvider.addCipher(firestoreItem);

    if (!mounted) return;
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

  void _showError(String message) {
    setState(() {
      _validationError = message;
    });
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle
                  : (isError ? Icons.error : Icons.info),
              color: AppColors.white,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess
            ? AppColors.success
            : (isError ? AppColors.error : AppColors.primary),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _startVisualization({bool replay = false}) async {
    if (_result == null) return;

    _animationToken++;
    final token = _animationToken;

    setState(() {
      _isAnimating = true;
      _isPaused = false;
      _progress = 0;
      for (int i = 0; i < _visibleSections.length; i++) {
        _visibleSections[i] = false;
      }
      _revealedKeyCells = 0;
      _revealedMessageCells = 0;
      _activeMultiplicationRow = -1;
      _activeMultiplicationTerm = -1;
      _revealedModuloRows = 0;
      _revealedResultRows = 0;
      _revealedInverseCells = 0;
      _inverseDetailStep = 0;
      _revealedCofactorCells = 0;
      _revealedAdjugateCells = 0;
    });

    final totalSteps = _isDecryptMode ? 6 : 5;
    int completedStep = 0;

    bool ok = await _animateKeyMatrix(token);
    if (!ok) return;
    completedStep++;
    _setProgress(completedStep / totalSteps);

    ok = await _animateMessageVector(token);
    if (!ok) return;
    completedStep++;
    _setProgress(completedStep / totalSteps);

    ok = await _animateMultiplication(token);
    if (!ok) return;
    completedStep++;
    _setProgress(completedStep / totalSteps);

    ok = await _animateModulo(token);
    if (!ok) return;
    completedStep++;
    _setProgress(completedStep / totalSteps);

    ok = await _animateResult(token);
    if (!ok) return;
    completedStep++;
    _setProgress(completedStep / totalSteps);

    if (_isDecryptMode && _result?.steps.inverseDetails != null) {
      ok = await _animateInverseMatrix(token);
      if (!ok) return;
      completedStep++;
      _setProgress(completedStep / totalSteps);
    }

    if (!mounted || token != _animationToken) return;
    setState(() {
      _isAnimating = false;
      _isPaused = false;
      _activeMultiplicationRow = -1;
      _activeMultiplicationTerm = -1;
      _progress = 1;
    });
  }

  Future<bool> _animateKeyMatrix(int token) async {
    if (!mounted || token != _animationToken) return false;

    setState(() => _visibleSections[0] = true);
    for (int i = 1; i <= 9; i++) {
      if (!await _waitWithPause(180, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedKeyCells = i);
    }
    return true;
  }

  Future<bool> _animateMessageVector(int token) async {
    if (!mounted || token != _animationToken) return false;

    setState(() => _visibleSections[1] = true);
    for (int i = 1; i <= 3; i++) {
      if (!await _waitWithPause(220, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedMessageCells = i);
    }
    return true;
  }

  Future<bool> _animateMultiplication(int token) async {
    if (!mounted || token != _animationToken) return false;

    setState(() => _visibleSections[2] = true);

    for (int row = 0; row < 3; row++) {
      if (!await _waitWithPause(180, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() {
        _activeMultiplicationRow = row;
        _activeMultiplicationTerm = -1;
      });

      for (int term = 0; term < 3; term++) {
        if (!await _waitWithPause(240, token)) return false;
        if (!mounted || token != _animationToken) return false;
        setState(() => _activeMultiplicationTerm = term);
      }
    }

    return true;
  }

  Future<bool> _animateModulo(int token) async {
    if (!mounted || token != _animationToken) return false;

    setState(() => _visibleSections[3] = true);
    for (int i = 1; i <= 3; i++) {
      if (!await _waitWithPause(260, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedModuloRows = i);
    }
    return true;
  }

  Future<bool> _animateResult(int token) async {
    if (!mounted || token != _animationToken) return false;

    setState(() => _visibleSections[4] = true);
    for (int i = 1; i <= 3; i++) {
      if (!await _waitWithPause(260, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedResultRows = i);
    }
    return true;
  }

  Future<bool> _animateInverseMatrix(int token) async {
    if (!mounted || token != _animationToken) return false;

    setState(() => _visibleSections[5] = true);

    for (int step = 1; step <= 4; step++) {
      if (!await _waitWithPause(260, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _inverseDetailStep = step);
    }

    for (int i = 1; i <= 9; i++) {
      if (!await _waitWithPause(130, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedCofactorCells = i);
    }

    for (int i = 1; i <= 9; i++) {
      if (!await _waitWithPause(130, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedAdjugateCells = i);
    }

    for (int i = 1; i <= 9; i++) {
      if (!await _waitWithPause(170, token)) return false;
      if (!mounted || token != _animationToken) return false;
      setState(() => _revealedInverseCells = i);
    }
    return true;
  }

  Future<bool> _waitWithPause(int milliseconds, int token) async {
    int elapsed = 0;

    while (elapsed < milliseconds) {
      if (!mounted || token != _animationToken) {
        return false;
      }

      await Future<void>.delayed(const Duration(milliseconds: 40));

      if (!_isPaused) {
        elapsed += 40;
      }
    }

    return true;
  }

  void _setProgress(double value) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0, 1);
    });
  }

  void _togglePlayPause() {
    if (_isAnimating) {
      setState(() => _isPaused = !_isPaused);
      return;
    }

    if (_result != null) {
      _startVisualization(replay: true);
    }
  }

  void _resetAll() {
    _animationToken++;
    setState(() {
      _isAnimating = false;
      _isPaused = false;
      _progress = 0;
      _validationError = null;
      _outputText = '';
      _result = null;
      _isDecryptMode = false;
      _showAddToHistory = false;
      for (int i = 0; i < _visibleSections.length; i++) {
        _visibleSections[i] = false;
      }
      _revealedKeyCells = 0;
      _revealedMessageCells = 0;
      _activeMultiplicationRow = -1;
      _activeMultiplicationTerm = -1;
      _revealedModuloRows = 0;
      _revealedResultRows = 0;
      _revealedInverseCells = 0;
      _inverseDetailStep = 0;
      _revealedCofactorCells = 0;
      _revealedAdjugateCells = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isMobile = media.isMobile;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.grid_3x3, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            const Text('Hill Cipher'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/cipher_history'),
            tooltip: 'View History',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildInputSection(isMobile),
            const SizedBox(height: AppSpacing.lg),
            _buildAnimationControls(),
            const SizedBox(height: AppSpacing.lg),
            if (_isAnimating || result != null) _buildProgressCard(),
            if (_isAnimating || result != null)
              const SizedBox(height: AppSpacing.lg),
            if (_validationError != null) _buildErrorCard(_validationError!),
            if (_validationError != null) const SizedBox(height: AppSpacing.lg),
            if (result != null) ...[
              _buildKeyMatrixSection(result),
              const SizedBox(height: AppSpacing.lg),
              _buildMessageVectorSection(result),
              const SizedBox(height: AppSpacing.lg),
              _buildMultiplicationSection(result),
              const SizedBox(height: AppSpacing.lg),
              _buildModuloSection(result),
              const SizedBox(height: AppSpacing.lg),
              _buildResultSection(result),
              const SizedBox(height: AppSpacing.lg),
              _buildOutputActionsCard(),
              if (_isDecryptMode && result.steps.inverseDetails != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildInverseSection(result.steps.inverseDetails!),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isMobile) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Section',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _textController,
              maxLength: 3,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plaintext / Ciphertext',
                hintText: 'Enter up to 3 letters (A-Z)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final sanitized = HillCipherLogic.sanitizeAZ(value);
                if (sanitized != value.toUpperCase()) {
                  _textController.value = TextEditingValue(
                    text: sanitized,
                    selection: TextSelection.collapsed(
                      offset: sanitized.length,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _keyController,
              maxLength: 9,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
              ],
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Key (9 letters)',
                hintText: 'Example: GYBNQKURP',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final sanitized = HillCipherLogic.sanitizeAZ(value);
                if (sanitized != value.toUpperCase()) {
                  _keyController.value = TextEditingValue(
                    text: sanitized,
                    selection: TextSelection.collapsed(
                      offset: sanitized.length,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnimating ? null : _encrypt,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Encrypt'),
                ),
                ElevatedButton.icon(
                  onPressed: _isAnimating ? null : _decrypt,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Decrypt'),
                ),
                OutlinedButton.icon(
                  onPressed: _resetAll,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            if (_outputText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '${_isDecryptMode ? 'Decrypted' : 'Encrypted'} Output: $_outputText',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            if (!isMobile) const SizedBox(height: AppSpacing.xs),
            Text(
              'Input shorter than 3 letters is auto-padded with X.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationControls() {
    final icon = _isAnimating
        ? (_isPaused ? Icons.play_arrow : Icons.pause)
        : Icons.play_circle_outline;

    final label = _isAnimating
        ? (_isPaused ? 'Resume Animation' : 'Pause Animation')
        : 'Play Animation';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Visualization Controls',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _result == null ? null : _togglePlayPause,
              icon: Icon(icon),
              label: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isAnimating
                  ? (_isPaused
                        ? 'Animation paused'
                        : 'Animating step-by-step...')
                  : 'Animation complete',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: AppSpacing.xs),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMatrixSection(HillCipherResult result) {
    return _buildAnimatedStepCard(
      visible: _visibleSections[0],
      title: '1) Key Matrix (3×3)',
      color: Colors.blue.shade100,
      child: _buildMatrixGrid(
        matrix: result.steps.keyMatrix,
        color: Colors.blue,
        revealedCells: _revealedKeyCells,
      ),
    );
  }

  Widget _buildMessageVectorSection(HillCipherResult result) {
    return _buildAnimatedStepCard(
      visible: _visibleSections[1],
      title: '2) Message Vector (3×1)',
      color: Colors.green.shade100,
      child: Column(
        children: List.generate(3, (index) {
          final isVisible = _revealedMessageCells > index;
          final letter = result.steps.inputLetters[index];
          final value = result.steps.messageVector[index];

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isVisible ? 1 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Letter: $letter'),
                  Text(
                    'Number: $value',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMultiplicationSection(HillCipherResult result) {
    return _buildAnimatedStepCard(
      visible: _visibleSections[2],
      title: '3) Matrix Multiplication',
      color: Colors.orange.shade100,
      child: Column(
        children: List.generate(3, (row) {
          final isActiveRow = _activeMultiplicationRow == row;
          final terms = result.steps.multiplicationTerms[row];
          final formula = '(${terms.join(' + ')}) % 26';
          final raw = result.steps.rawProducts[row];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isActiveRow
                  ? Colors.orange.shade50
                  : Colors.orange.shade100.withOpacity(0.4),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isActiveRow ? Colors.orange : Colors.orange.shade200,
                width: isActiveRow ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildBracketedMatrix(
                        title: 'K',
                        matrix: result.steps.keyMatrix,
                        highlightedRow: row,
                        highlightColor: Colors.orange,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          '×',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildBracketedVector(
                        title: 'M',
                        vector: result.steps.messageVector,
                        highlightedIndex: _activeMultiplicationTerm,
                        highlightColor: Colors.orange,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          '=',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildBracketedVector(
                        title: 'R',
                        vector: result.steps.resultVector,
                        highlightedIndex: row,
                        highlightColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'a${row + 1}1×b11 → + a${row + 1}2×b21 → + a${row + 1}3×b31',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Row ${row + 1}: $formula = $raw',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List.generate(terms.length, (termIndex) {
                    final isActive =
                        isActiveRow && _activeMultiplicationTerm == termIndex;
                    final chip = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.orange
                            : Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        terms[termIndex],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );

                    if (!isActive) return chip;

                    return AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: chip,
                    );
                  }),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildModuloSection(HillCipherResult result) {
    return _buildAnimatedStepCard(
      visible: _visibleSections[3],
      title: '4) Mod 26',
      color: Colors.purple.shade100,
      child: Column(
        children: List.generate(3, (index) {
          final isVisible = _revealedModuloRows > index;
          final raw = result.steps.rawProducts[index];
          final mod = result.steps.modResults[index];

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: isVisible ? 1 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Raw: $raw'),
                  Text(
                    '$raw mod 26 = $mod',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResultSection(HillCipherResult result) {
    return _buildAnimatedStepCard(
      visible: _visibleSections[4],
      title: '5) Result Vector → Text',
      color: Colors.red.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(3, (index) {
            final isVisible = _revealedResultRows > index;
            final number = result.steps.resultVector[index];
            final letter = result.steps.resultLetters[index];

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              opacity: isVisible ? 1 : 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Number: $number'),
                    Text(
                      'Letter: $letter',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Output: $_outputText',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputActionsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Output Actions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _outputText.isEmpty
                  ? null
                  : () => _copyToClipboard(_outputText),
              tooltip: 'Copy Output',
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: _showAddToHistory && _outputText.isNotEmpty
                  ? _addToHistory
                  : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Add to History'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInverseSection(MatrixInverseDetails details) {
    final keyMatrix = _result?.steps.keyMatrix;

    return _buildAnimatedStepCard(
      visible: _visibleSections[5],
      title: '6) Inverse Matrix (Decryption)',
      color: Colors.blueGrey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (keyMatrix != null) ...[
            Text('Key Matrix A', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _buildBracketedMatrix(
              title: 'A',
              matrix: keyMatrix,
              highlightedRow: -1,
              highlightColor: Colors.blueGrey,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _inverseDetailStep >= 1 ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'det(A) = a(ei - fh) - b(di - fg) + c(dh - eg)',
                  style: TextStyle(
                    color: Colors.blueGrey.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('det(A) = ${details.determinant}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _inverseDetailStep >= 2 ? 1 : 0,
            child: Text(
              'det(A) mod 26 = ${details.determinantMod26}',
              style: TextStyle(
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _inverseDetailStep >= 3 ? 1 : 0,
            child: Text(
              '(det(A))⁻¹ mod 26 = ${details.determinantInverseMod26}',
              style: TextStyle(
                color: Colors.deepPurple.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _inverseDetailStep >= 4 ? 1 : 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cofactor Matrix C (animated)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildMatrixGrid(
                  matrix: details.cofactorMatrix,
                  color: Colors.blueGrey,
                  revealedCells: _revealedCofactorCells,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Adjugate Matrix adj(A) = Cᵀ (animated)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildMatrixGrid(
                  matrix: details.adjugateMatrix,
                  color: Colors.blueGrey,
                  revealedCells: _revealedAdjugateCells,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'A⁻¹ = (det(A))⁻¹ × adj(A) mod 26',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildMatrixGrid(
                  matrix: details.inverseMatrix,
                  color: Colors.indigo,
                  revealedCells: _revealedInverseCells,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixGrid({
    required List<List<int>> matrix,
    required MaterialColor color,
    required int revealedCells,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - (AppSpacing.sm * 2)) / 3;
        return Column(
          children: List.generate(3, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: List.generate(3, (col) {
                  final index = row * 3 + col;
                  final visible = revealedCells > index;
                  final rowShade = [100, 200, 300][row];

                  return Padding(
                    padding: EdgeInsets.only(
                      right: col == 2 ? 0 : AppSpacing.sm,
                    ),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 320),
                      opacity: visible ? 1 : 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        width: cellWidth,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color[rowShade],
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          matrix[row][col].toString(),
                          style: TextStyle(
                            color: rowShade >= 300
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildBracketedMatrix({
    required String title,
    required List<List<int>> matrix,
    int highlightedRow = -1,
    required Color highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        _buildBracketWrap(
          child: Column(
            children: List.generate(3, (row) {
              return Row(
                children: List.generate(3, (col) {
                  final isHighlighted = row == highlightedRow;
                  return Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.all(2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? highlightColor.withOpacity(0.85)
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      matrix[row][col].toString(),
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBracketedVector({
    required String title,
    required List<int> vector,
    int highlightedIndex = -1,
    required Color highlightColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xs),
        _buildBracketWrap(
          child: Column(
            children: List.generate(3, (index) {
              final isHighlighted = index == highlightedIndex;
              return Container(
                width: 34,
                height: 32,
                margin: const EdgeInsets.all(2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? highlightColor.withOpacity(0.85)
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  vector[index].toString(),
                  style: TextStyle(
                    color: isHighlighted ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBracketWrap({required Widget child}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBracketSide(isLeft: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: child,
          ),
          _buildBracketSide(isLeft: false),
        ],
      ),
    );
  }

  Widget _buildBracketSide({required bool isLeft}) {
    return SizedBox(
      width: 10,
      child: Column(
        children: [
          Align(
            alignment: isLeft ? Alignment.topLeft : Alignment.topRight,
            child: Container(
              width: 8,
              height: 2,
              color: Colors.blueGrey.shade700,
            ),
          ),
          Expanded(
            child: Align(
              alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(width: 2, color: Colors.blueGrey.shade700),
            ),
          ),
          Align(
            alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
            child: Container(
              width: 8,
              height: 2,
              color: Colors.blueGrey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStepCard({
    required bool visible,
    required String title,
    required Widget child,
    required Color color,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 350),
      opacity: visible ? 1 : 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: visible ? color.withOpacity(0.28) : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: color.withOpacity(0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
