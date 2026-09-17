import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _noticesRef =>
      _firestore.collection('notices');

  /// Creates a new notice. Called only from CreateNoticeScreen, which is
  /// only reachable by Faculty/Super Admin — but this service itself does
  /// not enforce that; Firestore security rules are the real gate (Phase 6+).
  Future<void> createNotice({
    required String title,
    required String description,
    required String category,
    required String department,
    required String priority,
    required String postedBy,
    required String postedByName,
    DateTime? expiryDate,
  }) async {
    await _noticesRef.add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'department': department,
      'priority': priority,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'datePosted': FieldValue.serverTimestamp(),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate),
    });
  }

  /// Real-time stream of ALL notices, newest first.
  /// Used for the "All" filter.
  Stream<List<Notice>> streamAllNotices() {
    return _noticesRef
        .orderBy('datePosted', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Notice.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// Real-time stream of notices relevant to a specific department:
  /// general ("all") notices + that department's own notices.
  /// Filtered and merged client-side to avoid a composite Firestore index
  /// for an "in" query combined with orderBy on a different field.
  Stream<List<Notice>> streamNoticesForDepartment(String department) {
    return streamAllNotices().map((notices) => notices
        .where((n) => n.department == 'all' || n.department == department)
        .toList());
  }

  Future<void> deleteNotice(String noticeId) async {
    await _noticesRef.doc(noticeId).delete();
  }

  Future<void> updateNotice(String noticeId, Map<String, dynamic> updates) async {
    await _noticesRef.doc(noticeId).update(updates);
  }
}
