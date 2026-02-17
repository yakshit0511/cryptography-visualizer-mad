import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

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
