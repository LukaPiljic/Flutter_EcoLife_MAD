import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/eco_buddy_model.dart';
import '../../services/database_service.dart';
import '../../services/prefs_service.dart';
import '../../services/realtime_service.dart';
import '../../services/weather_service.dart';

class EcoBuddyScreen extends StatefulWidget {
  const EcoBuddyScreen({super.key});

  @override
  State<EcoBuddyScreen> createState() => _EcoBuddyScreenState();
}

class _EcoBuddyScreenState extends State<EcoBuddyScreen> {
  static const String _tag = 'EcoLifeBuddy';

  // Default Madrid coords (same as the Kotlin EcoBuddyActivity fallback).
  static const double _lat = 40.4168;
  static const double _lon = -3.7038;

  final _db = DatabaseService.instance;
  final _prefs = PrefsService();
  final _weatherService = WeatherService();
  final _realtime = RealtimeService();

  EcoBuddyModel? _buddy;
  bool _loading = true;

  double? _temp;
  int? _humidity;
  int? _aqi;
  String _weatherText = '';
  String _recommendations = '';

  @override
  void initState() {
    super.initState();
    developer.log('initState: EcoBuddyScreen created.', name: _tag);
    _load();
  }

  Future<void> _load() async {
    final buddy = await _db.getActiveBuddy();
    if (!mounted) return;
    setState(() {
      _buddy = buddy;
      _loading = false;
    });
    if (buddy != null) _fetchEnvironment();
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create your EcoBuddy'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name your EcoBuddy'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                context, controller.text.trim().isEmpty
                    ? 'EcoBuddy'
                    : controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null) return;
    await _createBuddy(name);
  }

  Future<void> _createBuddy(String name) async {
    final now = DateTime.now();
    final buddy = EcoBuddyModel(
      name: name,
      createdAt: now,
      hp: 100.0,
      lastCheck: now,
      isAlive: true,
    );
    final id = await _db.insertBuddy(buddy);
    // Reload so the model carries its assigned id.
    final saved = await _db.getActiveBuddy();
    if (!mounted) return;
    setState(() => _buddy = saved ?? buddy);
    developer.log('_createBuddy: $name (id=$id)', name: _tag);
    _fetchEnvironment();
  }

  Future<void> _fetchEnvironment() async {
    final apiKey = await _prefs.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        setState(() => _weatherText =
            'Set your OpenWeatherMap API key in Settings to feed your EcoBuddy.');
      }
      return;
    }
    final weather = await _weatherService.fetchWeather(_lat, _lon, apiKey);
    final air = await _weatherService.fetchAirQuality(_lat, _lon, apiKey);
    if (!mounted) return;
    setState(() {
      _temp = weather?.temp;
      _humidity = weather?.humidity;
      _aqi = air?.aqi;
      if (weather != null) {
        _weatherText =
            '${weather.temp.toStringAsFixed(1)} °C   ·   Humidity ${weather.humidity}%'
            '${air != null ? '   ·   AQI ${air.aqi}' : ''}';
      } else {
        _weatherText = 'Weather data unavailable.';
      }
    });
    _applyEnvironmentEffects();
  }

  /// Gamification rules ported from the Kotlin applyEnvironmentEffects().
  Future<void> _applyEnvironmentEffects() async {
    final buddy = _buddy;
    if (buddy == null || !buddy.isAlive) return;

    double delta = 0;
    if (_temp != null && (_temp! < 0 || _temp! > 35)) delta -= 1.0;
    if (_aqi != null) {
      if (_aqi! >= 5) {
        delta -= 2.0;
      } else if (_aqi! >= 4) {
        delta -= 1.0;
      }
    }
    if (_humidity != null && (_humidity! < 30 || _humidity! > 80)) delta -= 0.5;
    if (delta == 0) delta = 0.5; // healthy conditions → recover

    final newHp = (buddy.hp + delta).clamp(0.0, 100.0);
    final updated = buddy.copyWith(
      hp: newHp,
      lastCheck: DateTime.now(),
      isAlive: newHp > 0,
    );
    await _db.updateBuddy(updated);
    if (mounted) setState(() => _buddy = updated);
    _updateRecommendations();
    _realtime.syncScore(updated); // fire-and-forget
    developer.log('_applyEnvironmentEffects: ${buddy.hp} → $newHp (Δ$delta)',
        name: _tag);
  }

  void _updateRecommendations() {
    final recs = <String>[];
    if (_buddy?.isAlive == false || (_buddy?.hp ?? 100) <= 0) {
      _recommendations =
          'Your EcoBuddy withered. Improve local conditions and create a new one.';
      return;
    }
    if (_temp != null && _temp! > 35) {
      recs.add('🔥 It is very hot — your EcoBuddy is heat-stressed.');
    }
    if (_temp != null && _temp! < 0) {
      recs.add('❄️ Freezing temperatures are hurting your EcoBuddy.');
    }
    if (_aqi != null && _aqi! >= 4) {
      recs.add('🌫 Poor air quality is draining your EcoBuddy.');
    }
    if (_humidity != null && _humidity! < 30) {
      recs.add('💧 The air is very dry.');
    }
    if (_humidity != null && _humidity! > 80) {
      recs.add('💦 Humidity is very high.');
    }
    if (recs.isEmpty) recs.add('🌿 Conditions are healthy — your EcoBuddy thrives!');
    _recommendations = recs.join('\n\n');
  }

  Color _hpColor(double hp) {
    if (hp > 60) return EcoColors.primary;
    if (hp > 30) return EcoColors.climateYellow;
    return EcoColors.climateRed;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_buddy == null) {
      return _createPrompt();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buddyCard(_buddy!),
          const SizedBox(height: 16),
          _weatherCard(),
          const SizedBox(height: 16),
          _recommendationsCard(),
        ],
      ),
    );
  }

  Widget _createPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🥚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'You don\'t have an EcoBuddy yet.\n'
              'Create one and keep it alive by improving your environment!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create EcoBuddy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buddyCard(EcoBuddyModel b) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(b.stageEmoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(b.name,
                style: Theme.of(context).textTheme.titleLarge),
            Text('${b.stageLabel}  ·  ${b.ageDays} day${b.ageDays == 1 ? '' : 's'} old',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.favorite, color: EcoColors.climateRed, size: 18),
                const SizedBox(width: 8),
                Text('${b.hp.toInt()} / 100 HP',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: b.hp / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(_hpColor(b.hp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weatherCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.cloud_outlined, color: EcoColors.primary),
        title: const Text('Local conditions',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(
          _weatherText.isEmpty ? 'Loading…' : _weatherText,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _recommendationsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommendations',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(_recommendations.isEmpty
                ? 'Feed your EcoBuddy by keeping the air clean and conditions mild.'
                : _recommendations),
          ],
        ),
      ),
    );
  }
}
