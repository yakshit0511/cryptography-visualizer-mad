class UserStats {
  final String userId;
  final int totalCiphersSolved;
  final int caesarCount;
  final int playfairCount;
  final DateTime lastActivity;
  final Map<String, dynamic> dailyStats;

  UserStats({
    required this.userId,
    required this.totalCiphersSolved,
    required this.caesarCount,
    required this.playfairCount,
    required this.lastActivity,
    required this.dailyStats,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['userId'] ?? '',
      totalCiphersSolved: map['totalCiphersSolved'] ?? 0,
      caesarCount: map['caesarCount'] ?? 0,
      playfairCount: map['playfairCount'] ?? 0,
      lastActivity: DateTime.parse(map['lastActivity'] ?? DateTime.now().toIso8601String()),
      dailyStats: Map<String, dynamic>.from(map['dailyStats'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalCiphersSolved': totalCiphersSolved,
      'caesarCount': caesarCount,
      'playfairCount': playfairCount,
      'lastActivity': lastActivity.toIso8601String(),
      'dailyStats': dailyStats,
    };
  }

  UserStats copyWith({
    String? userId,
    int? totalCiphersSolved,
    int? caesarCount,
    int? playfairCount,
    DateTime? lastActivity,
    Map<String, dynamic>? dailyStats,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalCiphersSolved: totalCiphersSolved ?? this.totalCiphersSolved,
      caesarCount: caesarCount ?? this.caesarCount,
      playfairCount: playfairCount ?? this.playfairCount,
      lastActivity: lastActivity ?? this.lastActivity,
      dailyStats: dailyStats ?? this.dailyStats,
    );
  }
}
