import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/coordinate_model.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';

class EcoLogScreen extends StatefulWidget {
  const EcoLogScreen({super.key});

  @override
  State<EcoLogScreen> createState() => _EcoLogScreenState();
}

class _EcoLogScreenState extends State<EcoLogScreen> {
  static const String _tag = 'EcoLifeEcoLog';
  final _db = DatabaseService.instance;
  List<CoordinateModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    developer.log('initState: EcoLogScreen created.', name: _tag);
    _load();
  }

  @override
  void dispose() {
    developer.log('dispose: EcoLogScreen destroyed.', name: _tag);
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _db.getCoordinates();
    developer.log('_load: ${entries.length} entries.', name: _tag);
    if (mounted) {
      setState(() {
        _entries = entries.reversed.toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return const Center(
        child: Text(
          'No coordinates logged yet.\nEnable tracking on the Home tab.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Column(
      children: [
        const _LogHeaderRow(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) =>
                  _LogItemRow(coord: _entries[index]),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom header row for the EcoLog list (mirrors the Kotlin listview_header).
class _LogHeaderRow extends StatelessWidget {
  const _LogHeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );
    return Container(
      color: EcoColors.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Time', style: style)),
          Expanded(flex: 3, child: Text('Coordinates', style: style)),
          Expanded(
            flex: 1,
            child: Text('Alt', style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Custom item row for the EcoLog list (mirrors the Kotlin listview_item +
/// CoordinatesAdapter).
class _LogItemRow extends StatelessWidget {
  final CoordinateModel coord;
  const _LogItemRow({required this.coord});

  String _fmtDate(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(dt.month)}-${p(dt.day)} ${p(dt.hour)}:${p(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.detail, arguments: coord),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                _fmtDate(coord.timestamp),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${coord.latitude.toStringAsFixed(4)}, '
                '${coord.longitude.toStringAsFixed(4)}',
                style: const TextStyle(
                    fontSize: 12, color: EcoColors.primaryDark),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                coord.altitude.toStringAsFixed(0),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
