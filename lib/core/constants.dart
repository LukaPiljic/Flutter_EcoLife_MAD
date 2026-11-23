class AppConstants {
  static const String appName = 'EcoLife';
  static const String appTagline = 'Raise your EcoBuddy. Heal your world.';
  static const String releaseTag = 'v7.0';
  static const String releaseName = 'EcoBuddy';
  static const Duration defaultAnimation = Duration(milliseconds: 250);

  // Realtime Database URL — FlutterFire's generated options omit it, so we
  // pass it explicitly to FirebaseDatabase.instanceFor. Replace with the URL of
  // your own Firebase Realtime Database.
  static const String databaseUrl =
      'https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com';

  // Paste the OAuth *web* client ID here to enable Google sign-in. Find it in
  // android/app/google-services.json (oauth_client → client_type 3) after
  // adding your SHA-1 and re-downloading the file, or in the Firebase console
  // under Authentication → Google → Web SDK configuration. Leave empty to show
  // only the email/password sign-in option.
  static const String googleWebClientId = '';

  static const List<String> observationTypes = [
    'Temperature (°C)',
    'Noise Level (dB)',
    'Air Quality (AQI)',
  ];
}
