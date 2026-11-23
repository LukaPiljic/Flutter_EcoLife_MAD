import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../core/constants.dart';
import '../models/eco_buddy_model.dart';
import '../models/observation_model.dart';
import '../models/ranking_entry.dart';

/// Wraps the Firebase Realtime Database. The generated FirebaseOptions omit the
/// database URL, so we resolve the instance explicitly with [AppConstants.databaseUrl].
class RealtimeService {
  static const String _tag = 'EcoLifeRealtime';

  FirebaseDatabase get _db => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: AppConstants.databaseUrl,
      );

  /// Pushes the EcoBuddy score to `rankings/{uid}` (fire-and-forget).
  Future<void> syncScore(EcoBuddyModel buddy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.ref('rankings/${user.uid}').set({
        'userId': user.uid,
        'displayName': user.displayName ?? user.email ?? 'Anonymous',
        'buddyName': buddy.name,
        'score': buddy.hp.toInt(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      developer.log('syncScore: ${buddy.hp.toInt()} HP synced', name: _tag);
    } catch (e) {
      developer.log('syncScore: failed $e', name: _tag);
    }
  }

  /// Mirrors a logged observation to `observations/{uid}` (fire-and-forget).
  Future<void> syncObservation(ObservationModel obs) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.ref('observations/${user.uid}').push().set({
        'userId': user.uid,
        'timestamp': obs.timestamp.millisecondsSinceEpoch,
        'type': obs.type,
        'value': obs.value,
        'note': obs.note,
        'latitude': obs.lat,
        'longitude': obs.lon,
      });
      developer.log('syncObservation: ${obs.type} synced', name: _tag);
    } catch (e) {
      developer.log('syncObservation: failed $e', name: _tag);
    }
  }

  /// Live ranking list, ordered by score descending.
  Stream<List<RankingEntry>> rankingsStream() {
    return _db.ref('rankings').orderByChild('score').onValue.map((event) {
      final entries = <RankingEntry>[];
      for (final child in event.snapshot.children) {
        final value = child.value;
        if (value is Map) entries.add(RankingEntry.fromMap(value));
      }
      entries.sort((a, b) => b.score.compareTo(a.score));
      return entries;
    });
  }
}
