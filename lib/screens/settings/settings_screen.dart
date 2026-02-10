import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/constants.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = 'Loading...';
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Dark Mode Setting
          Card(
            elevation: 2,
            child: SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Notifications Setting
          Card(
            elevation: 2,
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined, color: AppColors.secondary),
              title: const Text('Notifications'),
              subtitle: const Text('Manage notification preferences'),
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Language Setting
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.language_outlined, color: AppColors.info),
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Implement language selection
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // App Version
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.grey),
              title: const Text('App Version'),
              subtitle: Text(_appVersion),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // About Section
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.primary),
              title: const Text('About'),
              subtitle: const Text('Cryptography Visualizer - Learn ciphers visually'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cryptography Visualizer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Version: $_appVersion'),
            const SizedBox(height: 16),
            const Text(
              'A visual learning tool for understanding cryptographic ciphers including Caesar and Playfair ciphers.',
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2026 Cryptography Visualizer\nAll rights reserved.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
