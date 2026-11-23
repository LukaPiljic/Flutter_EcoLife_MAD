import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About EcoLife')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Release ${AppConstants.releaseTag} — ${AppConstants.releaseName}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          const Text(
            'EcoLife is a gamified environmental awareness app. You raise a '
            'virtual eco-creature — an EcoBuddy — whose health reflects the '
            'environmental quality of your surroundings. Live GPS, weather, and '
            'air-quality readings drive its HP; small daily improvements feed it.',
          ),
          const SizedBox(height: 24),
          Text(
            'Climate Cube methodology',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _ClimateCubeRow(
            color: EcoColors.climateRed,
            label: 'Red — environmental threats',
          ),
          const _ClimateCubeRow(
            color: EcoColors.climateYellow,
            label: 'Yellow — impacts on living things',
          ),
          const _ClimateCubeRow(
            color: EcoColors.climateGreen,
            label: 'Green — solutions',
          ),
          const SizedBox(height: 24),
          Text(
            'Release roadmap',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _ReleaseRow(tag: 'v1.0', name: 'Hello EcoLife',
            note: 'Setup, lifecycle logging, GPS permission, About'),
          const _ReleaseRow(tag: 'v2.0', name: 'EcoTracker',
            note: 'Location toggle, altitude, CSV storage, navigation'),
          const _ReleaseRow(tag: 'v3.0', name: 'EcoMap',
            note: 'OpenStreetMap, user marker, eco-POIs, green trail'),
          const _ReleaseRow(tag: 'v4.0', name: 'EcoDiary',
            note: 'AlertDialog, SharedPreferences, observation logging'),
          const _ReleaseRow(tag: 'v5.0', name: 'EcoLog & Navigation',
            note: 'ListView, Drawer, Bottom Nav, Toolbar'),
          const _ReleaseRow(tag: 'v6.0', name: 'EcoWeather & DB',
            note: 'sqflite, REST API, weather display, custom icon'),
          const _ReleaseRow(tag: 'v7.0', name: 'EcoBuddy',
            note: 'Firebase Auth, Realtime DB, gamification, ranking'),
          const SizedBox(height: 32),
          const Text(
            'Built for Mobile App Development, UPM 2026.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClimateCubeRow extends StatelessWidget {
  final Color color;
  final String label;
  const _ClimateCubeRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 16, height: 16, decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          )),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ReleaseRow extends StatelessWidget {
  final String tag;
  final String name;
  final String note;
  const _ReleaseRow({required this.tag, required this.name, required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(tag, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(note, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
