import 'package:cloud_firestore/cloud_firestore.dart';

/// Lightweight, one-off counts shown on the Profile screen — uses
/// Firestore's aggregate count() queries so only a number is fetched,
/// not every matching document.
class ProfileStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> _count(String collection, String field, String value) async {
    final snap = await _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> noticesPostedBy(String uid) => _count('notices', 'postedBy', uid);

  Future<int> eventsOrganizedBy(String uid) => _count('events', 'organizerId', uid);

  Future<int> lostFoundPostsBy(String uid) => _count('lost_found', 'postedBy', uid);

  Future<int> totalUsers() async {
    final snap = await _firestore.collection('users').count().get();
    return snap.count ?? 0;
  }

  Future<int> pendingApprovalsCount() => _count('users', 'role', 'pending');
}
