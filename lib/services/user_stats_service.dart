import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_stats.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Get user statistics
  Future<UserStats?> getUserStats() async {
    if (_currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('user_stats')
          .doc(_currentUserId)
          .get();

      if (doc.exists) {
        return UserStats.fromMap(doc.data()!);
      } else {
        // Create initial stats
        final initialStats = UserStats(
          userId: _currentUserId!,
          totalCiphersSolved: 0,
          caesarCount: 0,
          playfairCount: 0,
          lastActivity: DateTime.now(),
          dailyStats: {},
        );
        await _firestore
            .collection('user_stats')
            .doc(_currentUserId)
            .set(initialStats.toMap());
        return initialStats;
      }
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }

  // Increment cipher solve count
  Future<void> incrementCipherCount(String cipherType) async {
    if (_currentUserId == null) return;

    try {
      final docRef = _firestore.collection('user_stats').doc(_currentUserId);
      final today = DateTime.now().toIso8601String().split('T')[0];

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          // Create new stats document
          transaction.set(docRef, {
            'userId': _currentUserId,
            'totalCiphersSolved': 1,
            'caesarCount': cipherType == 'Caesar' ? 1 : 0,
            'playfairCount': cipherType == 'Playfair' ? 1 : 0,
            'lastActivity': DateTime.now().toIso8601String(),
            'dailyStats': {today: 1},
          });
        } else {
          final currentStats = UserStats.fromMap(snapshot.data()!);
          final updatedDailyStats = Map<String, dynamic>.from(currentStats.dailyStats);
          updatedDailyStats[today] = (updatedDailyStats[today] ?? 0) + 1;

          transaction.update(docRef, {
            'totalCiphersSolved': currentStats.totalCiphersSolved + 1,
            'caesarCount': cipherType == 'Caesar'
                ? currentStats.caesarCount + 1
                : currentStats.caesarCount,
            'playfairCount': cipherType == 'Playfair'
                ? currentStats.playfairCount + 1
                : currentStats.playfairCount,
            'lastActivity': DateTime.now().toIso8601String(),
            'dailyStats': updatedDailyStats,
          });
        }
      });
    } catch (e) {
      print('Error incrementing cipher count: $e');
    }
  }

  // Stream of user stats for real-time updates
  Stream<UserStats?> getUserStatsStream() {
    if (_currentUserId == null) return Stream.value(null);

    return _firestore
        .collection('user_stats')
        .doc(_currentUserId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserStats.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Get daily activity chart data (last 7 days)
  Future<Map<String, int>> getDailyActivity() async {
    final stats = await getUserStats();
    if (stats == null) return {};

    final Map<String, int> dailyActivity = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      dailyActivity[dateStr] = stats.dailyStats[dateStr] ?? 0;
    }

    return dailyActivity;
  }
}
