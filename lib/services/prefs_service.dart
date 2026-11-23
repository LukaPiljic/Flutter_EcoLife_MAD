import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Key-value preferences (nickname + OpenWeatherMap API key). Structured
/// records (coordinates, observations) live in [DatabaseService] instead.
class PrefsService {
  static const String _tag = 'EcoLifePrefs';
  static const String _keyNickname = 'userNickname';
  static const String _keyApiKey = 'API_KEY';

  Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNickname);
  }

  Future<void> setNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, nickname);
    developer.log('setNickname: $nickname', name: _tag);
  }

  Future<void> resetNickname() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNickname);
    developer.log('resetNickname: nickname cleared', name: _tag);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<void> setApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, apiKey);
    developer.log('setApiKey: key saved', name: _tag);
  }
}
