import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final providers = <AuthProvider>[
      EmailAuthProvider(),
      if (AppConstants.googleWebClientId.isNotEmpty)
        GoogleProvider(clientId: AppConstants.googleWebClientId),
    ];

    return SignInScreen(
      providers: providers,
      // Give the header enough room for the logo + title at rest.
      headerMaxExtent: 200,
      // The header is laid out inside a fixed-height SliverPersistentHeader,
      // so wrapping the content in a scaleDown FittedBox guarantees it can
      // never overflow — it shrinks to fit whatever vertical space the header
      // band currently has (on scroll, on small screens, or with the keyboard
      // open).
      headerBuilder: (context, constraints, _) => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 64, color: EcoColors.primary),
                SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: EcoColors.primaryDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gamified Environmental Awareness',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
