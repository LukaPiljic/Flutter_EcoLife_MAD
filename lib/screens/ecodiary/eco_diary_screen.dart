import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/observation_model.dart';
import '../../services/database_service.dart';

class EcoDiaryScreen extends StatefulWidget {
  const EcoDiaryScreen({super.key});

  @override
  State<EcoDiaryScreen> createState() => _EcoDiaryScreenState();
}

class _EcoDiaryScreenState extends State<EcoDiaryScreen> {
  static const String _tag = 'EcoLifeEcoDiary';
  final _db = DatabaseService.instance;
  List<ObservationModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    developer.log('initState: EcoDiaryScreen created.', name: _tag);
    _load();
  }

  @override
  void dispose() {
    developer.log('dispose: EcoDiaryScreen destroyed.', name: _tag);
    super.dispose();
  }

  Future<void> _load() async {
    final entries = await _db.getObservations();
    developer.log('_load: ${entries.length} observations.', name: _tag);
    if (mounted) {
      setState(() {
        _entries = entries.reversed.toList();
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime dt) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${p(dt.month)}-${p(dt.day)} '
        '${p(dt.hour)}:${p(dt.minute)}:${p(dt.second)}';
  }

  IconData _iconFor(String type) {
    if (type.startsWith('Temperature')) return Icons.thermostat;
    if (type.startsWith('Noise')) return Icons.volume_up;
    return Icons.air;
  }

  void _showDetail(ObservationModel obs) {
    developer.log('_showDetail: ${obs.type}', name: _tag);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(_iconFor(obs.type), color: EcoColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Observation Detail')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Type', obs.type),
            _detailRow('Value', obs.value),
            _detailRow('Note', obs.note.isEmpty ? '—' : obs.note),
            _detailRow('Location', '${obs.lat}, ${obs.lon}'),
            _detailRow('Logged', _fmtDate(obs.timestamp)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoDiary')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(
                  child: Text(
                    'No observations yet.\nLog one from the home screen.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) => _entryTile(_entries[index]),
                ),
    );
  }

  Widget _entryTile(ObservationModel obs) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: EcoColors.primary,
          foregroundColor: Colors.white,
          child: Icon(_iconFor(obs.type), size: 20),
        ),
        title: Text(obs.type),
        subtitle: Text(
          '${obs.value}  ·  ${_fmtDate(obs.timestamp)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showDetail(obs),
      ),
    );
  }
}
