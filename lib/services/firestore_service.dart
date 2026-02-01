import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/firestore_history_item.dart';

/// Firestore Service for History Management
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name
  static const String _collectionName = 'history';

  /// Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Add history item to Firestore
  Future<bool> addHistory(FirestoreHistoryItem item) async {
    try {
      if (_userId == null) {
        print('Error: User not authenticated');
        return false;
      }

      // Add user ID to the document
      final data = item.toMap();
      data['userId'] = _userId;

      await _firestore.collection(_collectionName).add(data);
      
      print('✅ History saved to Firestore successfully');
      return true;
    } catch (e) {
      print('❌ Error saving history to Firestore: $e');
      return false;
    }
  }

  /// Get history stream for current user
  Stream<List<FirestoreHistoryItem>> getHistoryStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreHistoryItem.fromFirestore(doc))
          .toList();
    });
  }

  /// Get all history items for current user (one-time fetch)
  Future<List<FirestoreHistoryItem>> getHistory() async {
    try {
      if (_userId == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FirestoreHistoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching history: $e');
      return [];
    }
  }

  /// Update specific history item
  Future<bool> updateHistory(String documentId, FirestoreHistoryItem item) async {
    try {
      if (_userId == null) {
        print('Error: User not authenticated');
        return false;
      }

      final data = item.toMap();
      data['userId'] = _userId;
      
      await _firestore.collection(_collectionName).doc(documentId).update(data);
      print('✅ History item updated');
      return true;
    } catch (e) {
      print('❌ Error updating history: $e');
      return false;
    }
  }

  /// Delete specific history item
  Future<bool> deleteHistory(String documentId) async {
    try {
      await _firestore.collection(_collectionName).doc(documentId).delete();
      print('✅ History item deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting history: $e');
      return false;
    }
  }

  /// Clear all history for current user
  Future<bool> clearHistory() async {
    try {
      if (_userId == null) {
        return false;
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _userId)
          .get();

      // Delete all documents in batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ All history cleared');
      return true;
    } catch (e) {
      print('❌ Error clearing history: $e');
      return false;
    }
  }

  /// Get history count for current user
  Future<int> getHistoryCount() async {
    try {
      if (_userId == null) {
        return 0;
      }

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting history count: $e');
      return 0;
    }
  }

  /// Get history by cipher type
  Stream<List<FirestoreHistoryItem>> getHistoryByCipher(String cipherType) {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: _userId)
        .where('cipherType', isEqualTo: cipherType)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FirestoreHistoryItem.fromFirestore(doc))
          .toList();
    });
  }
}
