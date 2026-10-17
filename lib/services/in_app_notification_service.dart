import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

/// Manages the per-user notification subcollection:
///   notifications/{uid}/items/{docId}
class InAppNotificationService {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) =>
      _firestore.collection('notifications').doc(uid).collection('items');

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Real-time stream of all notifications for a user, newest first.
  Stream<List<AppNotification>> streamNotifications(String uid) {
    return _itemsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream that emits the count of unread notifications (for badge dot).
  Stream<int> streamUnreadCount(String uid) {
    return _itemsRef(uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Writes a single notification doc for one user.
  Future<void> _writeOne({
    required String uid,
    required String title,
    required String body,
    required String type,
    required String refId,
  }) async {
    await _itemsRef(uid).add({
      'title': title,
      'body': body,
      'type': type,
      'refId': refId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Called after a notice is created.
  /// Queries all users in [department] (and 'all' → every active user)
  /// and writes a notification for each of them.
  Future<void> notifyNoticeCreated({
    required String noticeId,
    required String title,
    required String category,
    required String postedByName,
    required String department, // 'all' or a specific dept name
  }) async {
    Query<Map<String, dynamic>> q =
        _firestore.collection('users').where('status', isEqualTo: 'active');

    // Limit to target users: for dept notices only target that dept,
    // for 'all' → every active user
    if (department != 'all') {
      q = q.where('department', isEqualTo: department);
    }

    final snap = await q.get();
    final body = '$category · Posted by $postedByName';

    final futures = snap.docs
        .map((doc) => _writeOne(
              uid: doc.id,
              title: title,
              body: body,
              type: 'notice',
              refId: noticeId,
            ))
        .toList();

    await Future.wait(futures);
  }

  /// Called after an event is created. Notifies every active user.
  Future<void> notifyEventCreated({
    required String eventId,
    required String name,
    required String venue,
    required String organizerName,
  }) async {
    final snap = await _firestore
        .collection('users')
        .where('status', isEqualTo: 'active')
        .get();

    final body = '$venue · $organizerName';

    final futures = snap.docs
        .map((doc) => _writeOne(
              uid: doc.id,
              title: '🎉 New Event: $name',
              body: body,
              type: 'event',
              refId: eventId,
            ))
        .toList();

    await Future.wait(futures);
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Mark a single notification as read.
  Future<void> markRead(String uid, String notifId) async {
    await _itemsRef(uid).doc(notifId).update({'read': true});
  }

  /// Mark ALL unread notifications as read (called on opening the screen).
  Future<void> markAllRead(String uid) async {
    final snap =
        await _itemsRef(uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
