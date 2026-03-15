import 'package:flutter/material.dart';
import '../models/firestore_history_item.dart';
import '../models/history_item.dart';
import '../services/firestore_service.dart';
import '../services/history_service.dart';

class CipherProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<FirestoreHistoryItem> _cipherHistory = [];
  bool _isLoading = false;
  String? _error;
  bool _isListening = false;

  CipherProvider() {
    // Start listening to real-time updates
    startListening();
  }

  // Getters
  List<FirestoreHistoryItem> get cipherHistory => _cipherHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<HistoryItem> get _localHistory => HistoryService().history;

  int get totalCount {
    if (_cipherHistory.isNotEmpty) return _cipherHistory.length;
    return _localHistory.length;
  }

  int get caesarCount {
    if (_cipherHistory.isNotEmpty) {
      return _cipherHistory
          .where((item) => item.cipherType.toLowerCase().contains('caesar'))
          .length;
    }

    return _localHistory
        .where((item) => item.cipherName.toLowerCase().contains('caesar'))
        .length;
  }

  int get playfairCount {
    if (_cipherHistory.isNotEmpty) {
      return _cipherHistory
          .where((item) => item.cipherType.toLowerCase().contains('playfair'))
          .length;
    }

    return _localHistory
        .where((item) => item.cipherName.toLowerCase().contains('playfair'))
        .length;
  }

  int get hillCount {
    if (_cipherHistory.isNotEmpty) {
      return _cipherHistory
          .where((item) => item.cipherType.toLowerCase().contains('hill'))
          .length;
    }

    return _localHistory
        .where((item) => item.cipherName.toLowerCase().contains('hill'))
        .length;
  }

  /// Start listening to real-time updates
  void startListening() {
    if (_isListening) return;

    _isListening = true;
    _firestoreService.getHistoryStream().listen(
      (history) {
        _cipherHistory = history;
        _isLoading = false;
        _error = null;
        notifyListeners();
        print(
          '📊 Cipher history updated: Total=${_cipherHistory.length}, Caesar=$caesarCount, Playfair=$playfairCount, Hill=$hillCount',
        );
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
        print('❌ Error in history stream: $error');
      },
    );
  }

  /// Load cipher history from Firestore
  Future<void> loadCipherHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Loading cipher history...');
      _cipherHistory = await _firestoreService.getHistory();
      _isLoading = false;
      notifyListeners();
      print('✅ Loaded ${_cipherHistory.length} items from Firestore');
      print(
        '   Caesar: $caesarCount, Playfair: $playfairCount, Hill: $hillCount',
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error loading history: $e');
    }
  }

  /// Add new cipher to history
  Future<bool> addCipher(FirestoreHistoryItem item) async {
    try {
      print('➕ Adding cipher: ${item.cipherType}');
      final success = await _firestoreService.addHistory(item);
      if (success) {
        // Stream listener will automatically update the list
        print('✅ Cipher added successfully. Stream will update UI.');
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update existing cipher
  Future<bool> updateCipher(
    String documentId,
    FirestoreHistoryItem item,
  ) async {
    try {
      final success = await _firestoreService.updateHistory(documentId, item);
      if (success) {
        await loadCipherHistory(); // Reload to get updated list
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete cipher from history
  Future<bool> deleteCipher(String documentId) async {
    try {
      final success = await _firestoreService.deleteHistory(documentId);
      if (success) {
        await loadCipherHistory(); // Reload to get updated list
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear all cipher history
  Future<bool> clearAllHistory() async {
    try {
      final success = await _firestoreService.clearHistory();
      if (success) {
        _cipherHistory = [];
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get cipher count
  Future<int> getCipherCount() async {
    try {
      return await _firestoreService.getHistoryCount();
    } catch (e) {
      return 0;
    }
  }

  /// Filter history by cipher type
  List<FirestoreHistoryItem> getHistoryByCipherType(String cipherType) {
    return _cipherHistory
        .where((item) => item.cipherType == cipherType)
        .toList();
  }

  /// Refresh history
  Future<void> refresh() async {
    await loadCipherHistory();
  }
}
