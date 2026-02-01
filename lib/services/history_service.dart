import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

/// Centralized History Service for Cipher Operations (Per-User)
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<HistoryItem> _history = [];
  
  String get _storageKey => 'cipher_history_${_auth.currentUser?.uid ?? "guest"}';
  
  List<HistoryItem> get history => List.unmodifiable(_history);
  
  /// Load history from SharedPreferences (per user)
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_storageKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _history.clear();
        _history.addAll(decoded.map((item) => HistoryItem.fromMap(item)).toList());
      }
    } catch (e) {
      print('Error loading history: $e');
    }
  }
  
  /// Save history to SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = json.encode(_history.map((item) => item.toMap()).toList());
      await prefs.setString(_storageKey, historyJson);
    } catch (e) {
      print('Error saving history: $e');
    }
  }
  
  /// Add item to history
  Future<void> addItem(HistoryItem item) async {
    _history.insert(0, item); // Add to beginning (most recent first)
    await _saveHistory();
  }
  
  /// Remove item from history
  Future<void> removeItem(String id) async {
    _history.removeWhere((item) => item.id == id);
    await _saveHistory();
  }
  
  /// Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }
  
  /// Get item by ID
  HistoryItem? getItem(String id) {
    try {
      return _history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Filter history by cipher name
  List<HistoryItem> getHistoryByCipher(String cipherName) {
    return _history.where((item) => item.cipherName == cipherName).toList();
  }
  
  /// Get all history items
  List<HistoryItem> getHistory() {
    return List.unmodifiable(_history);
  }
}
