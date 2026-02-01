import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cipher_model.dart';

class CipherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'cipher_history';

  // ==================== CREATE Operation ====================
  /// Saves a new cipher record to Firestore
  Future<Map<String, dynamic>> createCipherHistory({
    required String inputText,
    required String cipherType,
    required String key,
    required String resultText,
  }) async {
    try {
      await _firestore.collection(_collectionName).add({
        'inputText': inputText,
        'cipherType': cipherType,
        'key': key,
        'resultText': resultText,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Cipher history saved successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to save cipher history: $e',
      };
    }
  }

  // ==================== READ Operation ====================
  /// Gets a real-time stream of all cipher history records
  Stream<List<CipherModel>> getCipherHistoryStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CipherModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Gets a single cipher record by ID
  Future<CipherModel?> getCipherById(String id) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return CipherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets all cipher history as a one-time fetch
  Future<List<CipherModel>> getAllCipherHistory() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return CipherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== UPDATE Operation ====================
  /// Updates an existing cipher record
  Future<Map<String, dynamic>> updateCipherHistory({
    required String id,
    required String inputText,
    required String cipherType,
    required String key,
    required String resultText,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'inputText': inputText,
        'cipherType': cipherType,
        'key': key,
        'resultText': resultText,
      });

      return {
        'success': true,
        'message': 'Cipher history updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update cipher history: $e',
      };
    }
  }

  // ==================== DELETE Operation ====================
  /// Deletes a cipher record by ID
  Future<Map<String, dynamic>> deleteCipherHistory(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();

      return {
        'success': true,
        'message': 'Cipher history deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete cipher history: $e',
      };
    }
  }

  // ==================== BULK Operations ====================
  /// Deletes all cipher history records
  Future<Map<String, dynamic>> deleteAllCipherHistory() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();

      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }

      return {
        'success': true,
        'message': 'All cipher history deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete all cipher history: $e',
      };
    }
  }

  /// Gets count of total cipher records
  Future<int> getCipherHistoryCount() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection(_collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}
