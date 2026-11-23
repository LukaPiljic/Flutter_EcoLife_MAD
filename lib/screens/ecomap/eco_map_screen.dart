import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';

class EcoMapScreen extends StatefulWidget {
  const EcoMapScreen({super.key});

  @override
  State<EcoMapScreen> createState() => _EcoMapScreenState();
}

class _EcoMapScreenState extends State<EcoMapScreen> {
  static const String _tag = 'EcoLifeMap';

  // Eco-friendly green spaces in Madrid (near UPM Ciudad Universitaria)
  static const _pois = [
    (lat: 40.4308, lon: -3.7196, name: 'Parque del Oeste'),
    (lat: 40.4239, lon: -3.7297, name: 'Casa de Campo (North)'),
    (lat: 40.4150, lon: -3.7350, name: 'Casa de Campo (Center)'),
    (lat: 40.4628, lon: -3.7336, name: 'Dehesa de la Villa'),
    (lat: 40.4493, lon: -3.7278, name: 'Jardín Botánico UCM'),
  ];

  // Default centre — Jardín Botánico UCM (same as Kotlin fallback)
  static const _defaultCenter = LatLng(40.4493, -3.7278);

  late final MapController _mapController;
  LatLng _userPosition = _defaultCenter;
  bool _hasRealLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    developer.log('initState: EcoMapScreen starting.', name: _tag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, double>) {
      _userPosition = LatLng(args['lat']!, args['lon']!);
      _hasRealLocation = true;
      developer.log(
          'didChangeDependencies: location received '
          '[${_userPosition.latitude}][${_userPosition.longitude}]',
          name: _tag);
    } else {
      _userPosition = _defaultCenter;
      developer.log(
          'didChangeDependencies: no location — using default UPM coords.',
          name: _tag);
    }
  }

  @override
  void dispose() {
    developer.log('dispose: EcoMapScreen destroyed.', name: _tag);
    super.dispose();
  }

  List<LatLng> get _poiPoints =>
      _pois.map((p) => LatLng(p.lat, p.lon)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userPosition,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ecolife.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _poiPoints,
                color: EcoColors.primaryDark,
                strokeWidth: 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              // Eco-POI markers
              ..._pois.map(
                (p) => Marker(
                  point: LatLng(p.lat, p.lon),
                  width: 40,
                  height: 40,
                  child: _PoiMarker(p.name),
                ),
              ),
              // User location marker
              Marker(
                point: _userPosition,
                width: 44,
                height: 44,
                child: _UserMarker(_hasRealLocation),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Centre on my location',
        backgroundColor: EcoColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _mapController.move(_userPosition, 14),
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class _PoiMarker extends StatelessWidget {
  final String name;
  const _PoiMarker(this.name);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: const Icon(Icons.eco, color: EcoColors.climateGreen, size: 32),
    );
  }
}

class _UserMarker extends StatelessWidget {
  final bool isReal;
  const _UserMarker(this.isReal);

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_pin,
      color: isReal ? EcoColors.climateRed : Colors.grey,
      size: 36,
    );
  }
}
