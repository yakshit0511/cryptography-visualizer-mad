import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../config/constants.dart';
import '../../services/user_profile_service.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedGender;
  String? _profilePhotoPath;
  bool _isLoading = false;
  bool _isSaving = false;
  
  final UserProfileService _profileService = UserProfileService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Load existing user profile from Firestore
  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _showSnackBar('Error: User not authenticated', isError: true);
        return;
      }

      // Load profile photo from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _profilePhotoPath = authProvider.profilePhotoPath;

      final profileData = await _profileService.getUserProfile(uid);
      
      if (profileData != null && mounted) {
        setState(() {
          _nameController.text = profileData['name'] ?? '';
          _phoneController.text = profileData['phone'] ?? '';
          _selectedGender = profileData['gender'];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showSnackBar('Error loading profile', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Pick profile photo from gallery
  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profilePhotoPath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Error selecting photo', isError: true);
    }
  }

  /// Validate phone number (exactly 10 digits)
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Phone number must contain only digits';
    }
    return null;
  }

  /// Validate name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Save profile with username uniqueness check
  Future<void> _saveProfile() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if gender is selected
    if (_selectedGender == null) {
      _showSnackBar('Please select gender', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser?.uid;
      final email = _auth.currentUser?.email;
      
      if (uid == null || email == null) {
        _showSnackBar('Error: User not authenticated', isError: true);
        return;
      }

      final enteredName = _nameController.text.trim();

      // Check username uniqueness
      final isUnique = await _profileService.isUsernameUnique(enteredName, uid);
      
      if (!isUnique) {
        _showSnackBar('Username already taken', isError: true);
        return;
      }

      // Save profile
      final success = await _profileService.saveUserProfile(
        uid: uid,
        name: enteredName,
        email: email,
        phone: _phoneController.text.trim(),
        gender: _selectedGender!,
      );

      if (success && mounted) {
        // Update AuthProvider with new name and photo
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.updateUserName(enteredName);
        
        if (_profilePhotoPath != null && _profilePhotoPath!.isNotEmpty) {
          await authProvider.updateProfilePhoto(_profilePhotoPath!);
        }
        
        _showSnackBar('Profile updated successfully');
      } else {
        _showSnackBar('Failed to update profile', isError: true);
      }
    } catch (e) {
      print('Error saving profile: $e');
      _showSnackBar('Error saving profile', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Avatar with Photo Picker
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primary,
                            child: CircleAvatar(
                              radius: 57,
                              backgroundColor: isDark ? const Color(0xFF2C2C2C) : AppColors.white,
                              backgroundImage: _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty
                                  ? FileImage(File(_profilePhotoPath!))
                                  : null,
                              child: _profilePhotoPath == null || _profilePhotoPath!.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 70,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2C2C2C) : AppColors.white,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Display current email
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFFB0B0B0) : Colors.black54,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Profile Form Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFE0E0E0) : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                              ),
                              validator: _validateName,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Phone Field
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                              ),
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              validator: _validatePhone,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Gender Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.wc_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                              ),
                              items: _genderOptions.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedGender = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select gender';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Profile',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
