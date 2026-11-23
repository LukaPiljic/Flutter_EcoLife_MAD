import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/coordinate_model.dart';
import '../../models/observation_model.dart';
import '../../models/weather_model.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../services/location_service.dart';
import '../../services/prefs_service.dart';
import '../../services/realtime_service.dart';
import '../../services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const String _tag = 'EcoLifeHome';

  // Fallback location — Jardín Botánico UCM, Madrid (same as the EcoMap default).
  static const double _defaultLat = 40.4493;
  static const double _defaultLon = -3.7278;

  final _locationService = LocationService();
  final _db = DatabaseService.instance;
  final _prefs = PrefsService();
  final _weatherService = WeatherService();
  final _realtime = RealtimeService();
  StreamSubscription<Position>? _positionSub;

  bool _trackingEnabled = false;
  double? _lat;
  double? _lon;
  double? _alt;
  int _savedCount = 0;
  String? _nickname;
  int _observationCount = 0;

  WeatherModel? _weather;
  AirQuality? _air;
  bool _weatherLoading = false;
  String? _weatherMessage;
  bool _weatherFromFix = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    developer.log('initState: EcoLife ${AppConstants.releaseTag} starting up.',
        name: _tag);
    _loadSavedCount();
    _loadProfile();
    _loadWeather();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptNicknameIfNeeded());
  }

  Future<void> _loadProfile() async {
    final nickname = await _prefs.getNickname();
    final count = await _db.observationCount();
    if (mounted) {
      setState(() {
        _nickname = nickname;
        _observationCount = count;
      });
    }
  }

  Future<void> _loadWeather() async {
    final apiKey = await _prefs.getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _weatherLoading = false;
          _weatherMessage =
              'Set your OpenWeatherMap API key in Settings to see live weather.';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _weatherLoading = true;
        _weatherMessage = null;
      });
    }
    final lat = _lat ?? _defaultLat;
    final lon = _lon ?? _defaultLon;
    final weather = await _weatherService.fetchWeather(lat, lon, apiKey);
    final air = await _weatherService.fetchAirQuality(lat, lon, apiKey);
    if (mounted) {
      setState(() {
        _weather = weather;
        _air = air;
        _weatherLoading = false;
        _weatherMessage = weather == null ? 'Weather data unavailable.' : null;
      });
    }
  }

  Future<void> _promptNicknameIfNeeded() async {
    final nickname = await _prefs.getNickname();
    if (nickname != null || !mounted) return;
    developer.log('_promptNicknameIfNeeded: no nickname set, prompting.',
        name: _tag);
    await _showNicknameDialog();
  }

  Future<void> _showNicknameDialog() async {
    final controller = TextEditingController(text: _nickname ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Welcome to EcoLife!'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your nickname'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || !mounted) return;
    await _prefs.setNickname(result);
    _snack('Nickname saved: $result');
    await _loadProfile();
  }

  Future<void> _showAddObservationDialog() async {
    String type = AppConstants.observationTypes.first;
    final valueController = TextEditingController();
    final noteController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Log Eco-Observation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in AppConstants.observationTypes)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (v) => setLocalState(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration:
                    const InputDecoration(labelText: 'Value (e.g. 22.5)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final value = valueController.text.trim();
    if (value.isEmpty) {
      _snack('Please enter a value.');
      return;
    }
    final obs = ObservationModel(
      timestamp: DateTime.now(),
      type: type,
      value: value,
      note: noteController.text.trim(),
      lat: _lat != null ? _lat!.toStringAsFixed(4) : '0.0000',
      lon: _lon != null ? _lon!.toStringAsFixed(4) : '0.0000',
    );
    await _db.insertObservation(obs);
    _realtime.syncObservation(obs); // mirror to Realtime DB (fire-and-forget)
    _snack('Observation saved!');
    await _loadProfile();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    developer.log('dispose: tearing down Home screen.', name: _tag);
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('didChangeAppLifecycleState: $state', name: _tag);
    if (state == AppLifecycleState.paused) _stopTracking();
  }

  Future<void> _loadSavedCount() async {
    final count = await _db.coordinateCount();
    if (mounted) setState(() => _savedCount = count);
  }

  Future<void> _startTracking() async {
    await _locationService.start();
    if (!_locationService.isTracking) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required.')),
        );
      }
      return;
    }
    _positionSub = _locationService.positionStream.listen(_onPosition);
    if (mounted) setState(() => _trackingEnabled = true);
    developer.log('_startTracking: tracking started.', name: _tag);
  }

  void _stopTracking() {
    _locationService.stop();
    _positionSub?.cancel();
    _positionSub = null;
    if (mounted) setState(() => _trackingEnabled = false);
    developer.log('_stopTracking: tracking stopped.', name: _tag);
  }

  Future<void> _onPosition(Position pos) async {
    final coord = CoordinateModel(
      timestamp: DateTime.now(),
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
    );
    await _db.insertCoordinate(coord);
    if (mounted) {
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _alt = pos.altitude;
        _savedCount++;
      });
    }
    // Refresh weather once against the first real GPS fix (avoids per-fix spam).
    if (!_weatherFromFix) {
      _weatherFromFix = true;
      _loadWeather();
    }
  }

  String _fmt(double? v, int decimals) =>
      v == null ? '—' : v.toStringAsFixed(decimals);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _greeting(),
            const SizedBox(height: 12),
            _weatherCard(),
            const SizedBox(height: 12),
            _locationCard(),
            const SizedBox(height: 12),
            _actionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _greeting() {
    return Row(
      children: [
        const Icon(Icons.eco, color: EcoColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _nickname == null ? 'Hello, EcoExplorer!' : 'Hello, $_nickname!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  Widget _weatherCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud_outlined, color: EcoColors.primary),
                    const SizedBox(width: 8),
                    Text('EcoWeather',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh weather',
                  onPressed: _weatherLoading ? null : _loadWeather,
                ),
              ],
            ),
            const Divider(height: 20),
            _weatherBody(),
          ],
        ),
      ),
    );
  }

  Widget _weatherBody() {
    if (_weatherLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_weather == null) {
      return Text(
        _weatherMessage ?? 'Weather data unavailable.',
        style: const TextStyle(color: Colors.grey),
      );
    }
    final w = _weather!;
    return Row(
      children: [
        Image.network(
          w.iconUrl,
          width: 56,
          height: 56,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.cloud, size: 48, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${w.temp.toStringAsFixed(1)} °C',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: EcoColors.primaryDark),
              ),
              Text(
                _capitalize(w.description),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Humidity ${w.humidity}%'
                '${_air != null ? '   ·   AQI ${_air!.aqi} (${_air!.label})' : ''}',
                style:
                    const TextStyle(fontSize: 12, color: EcoColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _locationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _trackingEnabled ? Icons.gps_fixed : Icons.gps_off,
                      color: _trackingEnabled
                          ? EcoColors.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location tracker',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Switch(
                  value: _trackingEnabled,
                  activeThumbColor: EcoColors.primary,
                  onChanged: (on) =>
                      on ? _startTracking() : _stopTracking(),
                ),
              ],
            ),
            const Divider(height: 20),
            _coordRow('Latitude', _fmt(_lat, 4)),
            _coordRow('Longitude', _fmt(_lon, 4)),
            _coordRow('Altitude', _lat == null ? '—' : '${_fmt(_alt, 2)} m'),
            const SizedBox(height: 8),
            Text(
              '$_savedCount fix${_savedCount == 1 ? '' : 'es'} saved to database',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: EcoColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _showAddObservationDialog,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Log Observation'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.ecoDiary)
              .then((_) => _loadProfile()),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text('Open EcoDiary ($_observationCount)'),
        ),
      ],
    );
  }
}
