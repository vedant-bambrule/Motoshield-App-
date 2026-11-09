import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'services/push_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MotoShieldApp());
}

class MotoShieldApp extends StatelessWidget {
  const MotoShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOTOSHIELD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AuthGate(),
    );
  }
}

/// Shows the login screen or the app itself depending on real Firebase
/// auth state — no more hardcoded "always start at login."
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.orange)));
        }
        if (snapshot.hasData) {
          // Register for real push notifications once logged in.
          PushService().init();
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}
