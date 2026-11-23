import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  developer.log('main: launching EcoLife ${AppConstants.releaseTag}',
      name: 'EcoLifeApp');
  runApp(const EcoLifeApp());
}

class EcoLifeApp extends StatelessWidget {
  /// Lets widget tests inject a fake auth stream instead of Firebase's.
  final Stream<User?>? authStateOverride;

  const EcoLifeApp({super.key, this.authStateOverride});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: AuthGate(authStateOverride: authStateOverride),
      routes: AppRoutes.routes,
    );
  }
}
