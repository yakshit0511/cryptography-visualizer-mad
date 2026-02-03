import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Register user with email and password
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      // Validate inputs
      if (fullName.isEmpty) {
        return {
          'success': false,
          'message': 'Full name cannot be empty',
        };
      }

      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Password must be at least 6 characters',
        };
      }

      if (password != confirmPassword) {
        return {
          'success': false,
          'message': 'Passwords do not match',
        };
      }

      // Create user with Firebase
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with full name
      await userCredential.user?.updateDisplayName(fullName);
      await userCredential.user?.reload();

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', fullName);
      await prefs.setString('userId', userCredential.user?.uid ?? '');
      await prefs.setString('lastLoggedInUserId', userCredential.user?.uid ?? '');

      return {
        'success': true,
        'message': 'Registration successful',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Login user with email and password
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password are required',
        };
      }

      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      if (password.length < 6) {
        return {
          'success': false,
          'message': 'Invalid password',
        };
      }

      // Sign in with Firebase
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', userCredential.user?.displayName ?? '');
      await prefs.setString('userId', userCredential.user?.uid ?? '');
      await prefs.setString('lastLoggedInUserId', userCredential.user?.uid ?? '');

      return {
        'success': true,
        'message': 'Login successful',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Logout user
  Future<Map<String, dynamic>> logoutUser() async {
    try {
      await _firebaseAuth.signOut();

      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userEmail');
      await prefs.remove('userName');
      await prefs.remove('userId');

      return {
        'success': true,
        'message': 'Logout successful',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred during logout: $e',
      };
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      await _firebaseAuth.sendPasswordResetEmail(email: email);

      return {
        'success': true,
        'message': 'Password reset email sent successfully',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        return {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'isEmailVerified': user.emailVerified,
          'createdAt': user.metadata.creationTime,
          'lastSignIn': user.metadata.lastSignInTime,
          'userName': prefs.getString('userName'),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String displayName,
  }) async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', displayName);

        return {
          'success': true,
          'message': 'Profile updated successfully',
        };
      }
      return {
        'success': false,
        'message': 'No user logged in',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  // Helper: Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Helper: Get error message from Firebase error code
  String _getErrorMessage(String errorCode) {
    // Normalize codes to handle different formats (web vs mobile)
    final code = errorCode.toLowerCase();

    // Common Firebase Auth codes
    switch (code) {
      case 'user-not-found':
      case 'auth/user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'auth/wrong-password':
        return 'Incorrect password';
      case 'weak-password':
      case 'auth/weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
      case 'auth/email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
      case 'auth/invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
      case 'auth/user-disabled':
        return 'User account has been disabled';
      case 'too-many-requests':
      case 'auth/too-many-requests':
        return 'Too many login attempts. Please try again later';
      case 'operation-not-allowed':
      case 'auth/operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'invalid-credential':
      case 'auth/invalid-credential':
        return 'Invalid credentials';

      // Web / platform specific API key / project config issues
      case 'api-key-not-valid':
      case 'auth/api-key-not-valid':
      case 'auth/invalid-api-key':
      case 'invalid-api-key':
        return 'Firebase API key is invalid. Please add a valid Firebase configuration in lib/firebase_options.dart (apiKey/appId/projectId).';
      case 'app-not-authorized':
      case 'auth/app-not-authorized':
      case 'project-not-found':
        return 'Firebase project configuration not found or unauthorized. Check your Firebase project credentials in lib/firebase_options.dart.';

      default:
        // Fallback: if the code contains 'api' or 'key' give a helpful message
        if (code.contains('api') || code.contains('key') || code.contains('project')) {
          return 'Firebase configuration error: $errorCode. Ensure your Firebase config in lib/firebase_options.dart is correct.';
        }
        return 'An error occurred: $errorCode';
    }
  }
}
