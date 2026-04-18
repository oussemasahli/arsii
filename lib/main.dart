import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/welcome/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArsiiApp());
}

class ArsiiApp extends StatelessWidget {
  const ArsiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Informatics AI Tutor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const WelcomeScreen(),
    );
  }
}
