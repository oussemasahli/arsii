import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/student_service.dart';
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
///   - Signed in + no Firestore profile (or onboardingComplete == false) → EnrollmentScreen
///   - Signed in + onboardingComplete == true → DashboardScreen
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

        // Signed in → Check Firestore for onboarding status
        return FutureBuilder<bool>(
          future: StudentService().isOnboardingComplete()
              .timeout(const Duration(seconds: 10), onTimeout: () => false),
          builder: (context, onboardingSnap) {
            if (onboardingSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00D4FF),
                    strokeWidth: 2.5,
                  ),
                ),
              );
            }

            final isComplete = onboardingSnap.data ?? false;
            if (!isComplete) {
              return const EnrollmentScreen();
            }

            return const DashboardScreen();
          },
        );
      },
    );
  }
}
