import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String _profilePhotoPath = '';
  bool _isLoading = true;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get profilePhotoPath => _profilePhotoPath;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _syncProfileFromFirestore() async {
    try {
      final uid = _currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      if (data == null) return;

      final firestoreName = (data['name'] ?? '').toString();
      final firestorePhotoUrl = (data['photoUrl'] ?? '').toString();

      if (firestoreName.isNotEmpty) {
        _userName = firestoreName;
      }
      if (firestorePhotoUrl.isNotEmpty) {
        _profilePhotoPath = firestorePhotoUrl;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _userName);
      await prefs.setString('profilePhotoPath', _profilePhotoPath);
      if (_currentUser?.email != null) {
        _userEmail = _currentUser!.email!;
        await prefs.setString('userEmail', _userEmail);
      }
    } catch (e) {
      debugPrint('Error syncing profile from Firestore: $e');
    }
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = _authService.currentUser;
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userName = prefs.getString('userName') ?? '';
      _userEmail = prefs.getString('userEmail') ?? '';
      _profilePhotoPath = prefs.getString('profilePhotoPath') ?? '';

      if (_currentUser != null) {
        await _syncProfileFromFirestore();
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _authService.loginUser(
      email: email,
      password: password,
    );

    if (result['success']) {
      _currentUser = result['user'];
      _isLoggedIn = true;
      _userEmail = email;

      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('userName') ?? '';

      await _syncProfileFromFirestore();

      // Reload history for the newly logged-in user
      await HistoryService().loadHistory();

      notifyListeners();
    }

    return result;
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final result = await _authService.registerUser(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );

    if (result['success']) {
      _currentUser = result['user'];
      _isLoggedIn = true;
      _userName = fullName;
      _userEmail = email;

      await _syncProfileFromFirestore();

      // Reload history for this user
      await HistoryService().loadHistory();

      notifyListeners();
    }

    return result;
  }

  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    final result = await _authService.logoutUser();

    if (result['success']) {
      _currentUser = null;
      _isLoggedIn = false;
      _userName = '';
      _userEmail = '';
      _profilePhotoPath = '';

      // Reset history when user logs out
      await HistoryService().loadHistory();

      notifyListeners();
    }

    return result;
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('userName') ?? '';
      _userEmail = prefs.getString('userEmail') ?? '';
      _profilePhotoPath = prefs.getString('profilePhotoPath') ?? '';
      _currentUser = _authService.currentUser;
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (_currentUser != null) {
        await _syncProfileFromFirestore();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  /// Update user name
  Future<void> updateUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      _userName = name;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user name: $e');
    }
  }

  /// Update profile photo path
  Future<void> updateProfilePhoto(String photoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePhotoPath', photoPath);
      _profilePhotoPath = photoPath;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile photo: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _currentUser = _authService.currentUser;
    notifyListeners();
    return _isLoggedIn;
  }
}
