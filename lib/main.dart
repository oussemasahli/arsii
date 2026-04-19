import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/onboarding/enrollment_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthGate(),
    );
  }
}

/// Listens to Firebase auth state and routes accordingly.
///
/// Flow:
///   - Not signed in → WelcomeScreen (login)
///   - Signed in + new user (no onboarding) → EnrollmentScreen
///   - Signed in + returning user → DashboardScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D4FF),
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        // Not signed in → Login
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // Signed in → Check onboarding status
        // TODO: Replace with real Firestore check later.
        // For now, use a placeholder: treat all users as new on first sign-in.
        // Change `isNewUser` to `false` to test the returning-user flow.
        final user = snapshot.data!;
        final isNewUser = _checkIsNewUser(user);

        if (isNewUser) {
          return const EnrollmentScreen();
        }

        return const DashboardScreen();
      },
    );
  }

  /// Placeholder: treat users created in the last 60 seconds as "new".
  /// Replace with a real Firestore `users/{uid}/onboardingComplete` check later.
  bool _checkIsNewUser(dynamic user) {
    final metadata = user.metadata;
    if (metadata.creationTime == null) return false;
    final diff = DateTime.now().difference(metadata.creationTime!);
    return diff.inSeconds < 60;
  }
}
