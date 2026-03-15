import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cipher_model.dart';

class CipherHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collectionName = 'cipher_history';

  String? get _userId => _auth.currentUser?.uid;

  // ==================== CREATE Operation ====================
  /// Saves cipher history data to Firestore
  /// Validates input text and cipher type before saving
  /// Returns success/error message
  Future<Map<String, dynamic>> saveCipherHistory({
    required String inputText,
    required String cipherType,
    required String key,
    required String resultText,
    BuildContext? context,
  }) async {
    try {
      // Validation: Input text
      if (inputText.trim().isEmpty) {
        return {'success': false, 'message': 'Input text cannot be empty'};
      }

      // Validation: Cipher type
      if (cipherType.trim().isEmpty) {
        return {'success': false, 'message': 'Cipher type must be specified'};
      }

      // Validation: Result text
      if (resultText.trim().isEmpty) {
        return {'success': false, 'message': 'Result text cannot be empty'};
      }

      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Create data map for Firestore
      final data = {
        'userId': _userId,
        'inputText': inputText.trim(),
        'cipherType': cipherType.trim(),
        'key': key.trim(),
        'resultText': resultText.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection(_collectionName)
          .add(data);

      // Show success message if context is provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Cipher history saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return {
        'success': true,
        'message': 'Cipher history saved successfully',
        'docId': docRef.id,
      };
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to save: ${e.message}';

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      String errorMessage = 'An unexpected error occurred: $e';

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // ==================== READ Operation ====================
  /// Get real-time stream of all cipher history records
  /// Returns Stream of List<CipherModel>
  Stream<List<CipherModel>> getCipherHistoryStream() {
    if (_userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return CipherModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  /// Get cipher history as a one-time fetch
  Future<List<CipherModel>> getCipherHistory() async {
    try {
      if (_userId == null) {
        return [];
      }

      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return CipherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching cipher history: $e');
      return [];
    }
  }

  /// Get a single cipher record by ID
  Future<CipherModel?> getCipherById(String id) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return CipherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching cipher by ID: $e');
      return null;
    }
  }

  // ==================== UPDATE Operation ====================
  /// Updates an existing cipher history record
  /// Validates input before updating
  Future<Map<String, dynamic>> updateCipherHistory({
    required String id,
    required String inputText,
    required String cipherType,
    required String key,
    required String resultText,
    BuildContext? context,
  }) async {
    try {
      // Validation: Input text
      if (inputText.trim().isEmpty) {
        return {'success': false, 'message': 'Input text cannot be empty'};
      }

      // Validation: Cipher type
      if (cipherType.trim().isEmpty) {
        return {'success': false, 'message': 'Cipher type must be specified'};
      }

      // Validation: Result text
      if (resultText.trim().isEmpty) {
        return {'success': false, 'message': 'Result text cannot be empty'};
      }

      // Update data map
      final data = {
        'inputText': inputText.trim(),
        'cipherType': cipherType.trim(),
        'key': key.trim(),
        'resultText': resultText.trim(),
      };

      // Update in Firestore
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Ensure update only affects current user's data.
      final docRef = _firestore.collection(_collectionName).doc(id);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != _userId) {
        return {
          'success': false,
          'message': 'Cannot update record: not permitted.',
        };
      }

      await docRef.update(data);

      // Show success message if context is provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Cipher history updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return {
        'success': true,
        'message': 'Cipher history updated successfully',
      };
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to update: ${e.message}';

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      String errorMessage = 'An unexpected error occurred: $e';

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // ==================== DELETE Operation ====================
  /// Deletes a cipher history record
  /// Shows confirmation dialog before deletion if context is provided
  Future<Map<String, dynamic>> deleteCipherHistory({
    required String id,
    BuildContext? context,
    bool showConfirmation = true,
  }) async {
    try {
      // Show confirmation dialog if requested and context is available
      if (showConfirmation && context != null && context.mounted) {
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Delete Cipher History'),
              content: const Text(
                'Are you sure you want to delete this cipher history record? This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );

        // If user cancelled, return early
        if (confirmed != true) {
          return {'success': false, 'message': 'Deletion cancelled by user'};
        }
      }

      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Ensure delete only affects current user's data.
      final docRef = _firestore.collection(_collectionName).doc(id);
      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists || docSnapshot.data()?['userId'] != _userId) {
        return {
          'success': false,
          'message': 'Cannot delete record: not permitted.',
        };
      }

      // Delete from Firestore
      await docRef.delete();

      // Show success message if context is provided
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Cipher history deleted successfully!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return {
        'success': true,
        'message': 'Cipher history deleted successfully',
      };
    } on FirebaseException catch (e) {
      String errorMessage = 'Failed to delete: ${e.message}';

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      String errorMessage = 'An unexpected error occurred: $e';

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // ==================== Additional Helper Methods ====================

  /// Delete all cipher history records for a specific cipher type
  Future<Map<String, dynamic>> deleteByCipherType(String cipherType) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _userId)
          .where('cipherType', isEqualTo: cipherType)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return {
        'success': true,
        'message': 'Deleted ${snapshot.docs.length} records',
        'count': snapshot.docs.length,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete records: $e'};
    }
  }

  /// Get count of cipher history records
  Future<int> getCipherHistoryCount() async {
    try {
      if (_userId == null) {
        return 0;
      }

      AggregateQuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: _userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting count: $e');
      return 0;
    }
  }

  /// Search cipher history by input text
  Stream<List<CipherModel>> searchCipherHistory(String searchQuery) {
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
              .map((doc) => CipherModel.fromMap(doc.data(), doc.id))
              .where(
                (cipher) =>
                    cipher.inputText.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    cipher.resultText.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
        });
  }
}
