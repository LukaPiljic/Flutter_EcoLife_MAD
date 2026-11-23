class RankingEntry {
  final String displayName;
  final String buddyName;
  final int score;
  final int lastUpdated;

  const RankingEntry({
    required this.displayName,
    required this.buddyName,
    required this.score,
    required this.lastUpdated,
  });

  factory RankingEntry.fromMap(Map<dynamic, dynamic> map) {
    return RankingEntry(
      displayName: (map['displayName'] as String?) ?? 'Anonymous',
      buddyName: (map['buddyName'] as String?) ?? '—',
      score: (map['score'] as num?)?.toInt() ?? 0,
      lastUpdated: (map['lastUpdated'] as num?)?.toInt() ?? 0,
    );
  }
}
