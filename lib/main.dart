import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cryptography Visualizer',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const HomeScreen(), // Placeholder
        '/profile': (context) => const HomeScreen(), // Placeholder
        '/caesar': (context) => const HomeScreen(), // Placeholder
        '/playfair': (context) => const HomeScreen(), // Placeholder
      },
    );
  }
}
