import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

/// Calls the OpenWeatherMap REST API for current weather and air quality.
class WeatherService {
  static const String _tag = 'EcoLifeWeather';
  static const String _base = 'https://api.openweathermap.org/data/2.5';

  Future<WeatherModel?> fetchWeather(
      double lat, double lon, String apiKey) async {
    final uri = Uri.parse(
        '$_base/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey');
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        developer.log('fetchWeather: HTTP ${res.statusCode}', name: _tag);
        return null;
      }
      return WeatherModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      developer.log('fetchWeather: error $e', name: _tag);
      return null;
    }
  }

  Future<AirQuality?> fetchAirQuality(
      double lat, double lon, String apiKey) async {
    final uri =
        Uri.parse('$_base/air_pollution?lat=$lat&lon=$lon&appid=$apiKey');
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        developer.log('fetchAirQuality: HTTP ${res.statusCode}', name: _tag);
        return null;
      }
      return AirQuality.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      developer.log('fetchAirQuality: error $e', name: _tag);
      return null;
    }
  }
}
