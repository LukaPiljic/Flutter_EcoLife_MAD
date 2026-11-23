import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/ranking_entry.dart';
import '../../services/realtime_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _realtime = RealtimeService();
  late final Stream<List<RankingEntry>> _stream = _realtime.rankingsStream();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: StreamBuilder<List<RankingEntry>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load rankings.'));
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No rankings yet.\nRaise an EcoBuddy to join the leaderboard.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) =>
                _RankRow(rank: index + 1, entry: entries[index]),
          );
        },
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final RankingEntry entry;
  const _RankRow({required this.rank, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('#$rank',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: EcoColors.primaryDark)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(entry.buddyName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${entry.score} HP',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: EcoColors.primary)),
        ],
      ),
    );
  }
}
