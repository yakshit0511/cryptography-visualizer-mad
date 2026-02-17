import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user profiles in Firestore
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name
  static const String _collectionName = 'users';

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if username is unique (excluding current user)
  Future<bool> isUsernameUnique(String name, String currentUid) async {
    try {
      // Query for documents with same name
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('name', isEqualTo: name)
          .get();

      // If no documents found, username is unique
      if (querySnapshot.docs.isEmpty) {
        return true;
      }

      // Check if any document belongs to a different user
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUid) {
          // Found same username with different UID
          return false;
        }
      }

      // Same username but same UID (user's own profile)
      return true;
    } catch (e) {
      print('❌ Error checking username uniqueness: $e');
      // Return false on error to prevent overwriting
      return false;
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Save or update user profile
  Future<bool> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String gender,
  }) async {
    try {
      final data = {
        'name': name,
        'email': email,
        'phone': phone,
        'gender': gender,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use set with merge to create or update
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .set(data, SetOptions(merge: true));

      print('✅ User profile saved successfully');
      return true;
    } catch (e) {
      print('❌ Error saving user profile: $e');
      return false;
    }
  }

  /// Update specific fields in user profile
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .update(data);

      print('✅ User profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating user profile: $e');
      return false;
    }
  }

  /// Delete user profile
  Future<bool> deleteUserProfile(String uid) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(uid)
          .delete();

      print('✅ User profile deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting user profile: $e');
      return false;
    }
  }
}
