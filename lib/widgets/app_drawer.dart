import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: Container(
        color: AppColors.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: AppGradients.primaryGradient,
              ),
              accountName: Text(
                authProvider.userName.isEmpty ? 'User' : authProvider.userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              accountEmail: Text(
                authProvider.userEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.white,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppColors.white,
                child: Text(
                  authProvider.userName.isNotEmpty 
                      ? authProvider.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            
            // Home
            ListTile(
              leading: const Icon(Icons.home_rounded, color: AppColors.primary),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            
            const Divider(),
            
            // Cipher History
            ListTile(
              leading: const Icon(Icons.history_rounded, color: AppColors.secondary),
              title: const Text('Cipher History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/cipher_history');
              },
            ),
            
            // Profile
            ListTile(
              leading: const Icon(Icons.person_rounded, color: AppColors.info),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            
            // Settings
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: AppColors.grey),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            
            const Divider(),
            
            // Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Logout'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true && context.mounted) {
                  final result = await authProvider.logout();
                  if (result['success'] && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // App Version
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Cryptography Visualizer\nVersion 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
