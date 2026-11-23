import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/coordinate_model.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  static const String _tag = 'EcoLifeDetail';

  @override
  void initState() {
    super.initState();
    developer.log('initState: DetailScreen created.', name: _tag);
  }

  @override
  void dispose() {
    developer.log('dispose: DetailScreen destroyed.', name: _tag);
    super.dispose();
  }

  String _fmtDate(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${p(dt.month)}-${p(dt.day)} '
        '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final coord =
        ModalRoute.of(context)!.settings.arguments as CoordinateModel;

    return Scaffold(
      appBar: AppBar(title: const Text('Coordinate Detail')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_pin,
                    color: EcoColors.primary, size: 48),
                const SizedBox(height: 16),
                _row('Timestamp', _fmtDate(coord.timestamp)),
                const Divider(height: 24),
                _row('Latitude', coord.latitude.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _row('Longitude', coord.longitude.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _row('Altitude', '${coord.altitude.toStringAsFixed(2)} m'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Eco Log'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.grey)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
