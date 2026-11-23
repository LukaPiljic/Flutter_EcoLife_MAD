class EcoBuddyModel {
  final int? id;
  final String name;
  final DateTime createdAt;
  final double hp;
  final DateTime lastCheck;
  final bool isAlive;

  const EcoBuddyModel({
    this.id,
    required this.name,
    required this.createdAt,
    this.hp = 100.0,
    required this.lastCheck,
    this.isAlive = true,
  });

  int get ageDays => DateTime.now().difference(createdAt).inDays;

  /// Lifecycle stage label + emoji, driven by age and survival (mirrors the
  /// Kotlin EcoBuddyActivity stages).
  String get stageLabel {
    if (!isAlive || hp <= 0) return 'Withered';
    if (ageDays < 2) return 'Egg';
    if (ageDays < 5) return 'Sprout';
    if (ageDays < 10) return 'Growing';
    return 'Mature';
  }

  String get stageEmoji {
    if (!isAlive || hp <= 0) return '🥀';
    if (ageDays < 2) return '🥚';
    if (ageDays < 5) return '🌱';
    if (ageDays < 10) return '🌿';
    return '🌳';
  }

  EcoBuddyModel copyWith({double? hp, DateTime? lastCheck, bool? isAlive}) {
    return EcoBuddyModel(
      id: id,
      name: name,
      createdAt: createdAt,
      hp: hp ?? this.hp,
      lastCheck: lastCheck ?? this.lastCheck,
      isAlive: isAlive ?? this.isAlive,
    );
  }
}
