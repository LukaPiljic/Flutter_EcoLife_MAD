import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ecolife/main.dart';

/// Builds the app with a fake signed-in auth stream so the AuthGate shows the
/// shell without needing a real Firebase backend.
Widget signedInApp() {
  final auth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'test-uid', displayName: 'Tester'),
  );
  return EcoLifeApp(authStateOverride: auth.authStateChanges());
}

Future<void> pumpSignedIn(WidgetTester tester) async {
  await tester.pumpWidget(signedInApp());
  await tester.pump(); // let the auth stream emit
  await tester.pump(const Duration(milliseconds: 100)); // build the shell
}

void main() {
  setUpAll(() {
    // Use the FFI sqflite implementation for tests (no platform plugin).
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('signed-in user lands on the Home tab of the shell',
      (WidgetTester tester) async {
    await pumpSignedIn(tester);
    // Home tab is shown by default.
    expect(find.text('Location tracker'), findsOneWidget);
    // Bottom navigation destinations are present.
    expect(find.text('EcoMap'), findsWidgets);
    expect(find.text('EcoBuddy'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('navigation drawer builds with all destinations',
      (WidgetTester tester) async {
    await pumpSignedIn(tester);
    expect(find.text('Location tracker'), findsOneWidget); // Home tab

    // The shell Scaffold is the outermost one; open its drawer.
    final shell = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    shell.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Tab links plus the EcoDiary / Ranking / About / Logout entries.
    expect(find.widgetWithText(ListTile, 'Home'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'EcoBuddy'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Settings'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'EcoDiary'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Ranking'), findsOneWidget);
  });
}
