import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login/login_screen.dart';
import '../shell/main_shell.dart';

/// Routes between the sign-in screen and the app shell based on auth state.
/// [authStateOverride] lets tests inject a fake stream without Firebase.
class AuthGate extends StatelessWidget {
  final Stream<User?>? authStateOverride;

  const AuthGate({super.key, this.authStateOverride});

  @override
  Widget build(BuildContext context) {
    final stream = authStateOverride ?? FirebaseAuth.instance.authStateChanges();
    return StreamBuilder<User?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
