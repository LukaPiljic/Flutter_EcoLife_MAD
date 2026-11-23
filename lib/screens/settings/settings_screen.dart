import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/database_service.dart';
import '../../services/prefs_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _tag = 'EcoLifeSettings';
  final _prefs = PrefsService();
  final _db = DatabaseService.instance;
  final _apiKeyController = TextEditingController();

  String? _nickname;
  int _obsCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    developer.log('initState: SettingsScreen created.', name: _tag);
    _refresh();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final nickname = await _prefs.getNickname();
    final count = await _db.observationCount();
    final apiKey = await _prefs.getApiKey();
    developer.log('_refresh: nickname=$nickname, observations=$count',
        name: _tag);
    if (mounted) {
      setState(() {
        _nickname = nickname;
        _obsCount = count;
        _apiKeyController.text = apiKey ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      _toast('API key cannot be empty.');
      return;
    }
    await _prefs.setApiKey(key);
    _toast('API key saved.');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showChangeNicknameDialog() async {
    final controller = TextEditingController(text: _nickname ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change nickname'),
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

    if (result == null) return;
    if (result.isEmpty) {
      _toast('Nickname cannot be empty.');
      return;
    }
    await _prefs.setNickname(result);
    _toast('Nickname saved: $result');
    await _refresh();
  }

  Future<void> _resetNickname() async {
    await _prefs.resetNickname();
    _toast('Nickname has been reset.');
    await _refresh();
  }

  Future<void> _clearObservations() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear observations?'),
        content: const Text(
            'This permanently deletes all logged observations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: EcoColors.climateRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.clearObservations();
    _toast('All observations cleared.');
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _infoCard(
                  icon: Icons.person,
                  label: 'Your nickname',
                  value: _nickname ?? '(not set)',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: Icons.eco,
                  label: 'Observations logged',
                  value: '$_obsCount',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showChangeNicknameDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Change nickname'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _resetNickname,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset nickname'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _obsCount == 0 ? null : _clearObservations,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear observations'),
                ),
                const Divider(height: 40),
                Text(
                  'OpenWeatherMap API key',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Needed to show live weather on the Home tab.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste your API key here',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _saveApiKey,
                  icon: const Icon(Icons.save),
                  label: const Text('Save API key'),
                ),
              ],
            ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: EcoColors.primary),
        title: Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: EcoColors.primaryDark)),
      ),
    );
  }
}
