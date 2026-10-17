import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';
import 'in_app_notification_service.dart';

class NoticeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _noticesRef =>
      _firestore.collection('notices');

  /// Creates a new notice and fans out an in-app notification to
  /// every active user in the target department (or all users for 'all').
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
    final docRef = await _noticesRef.add({
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

    // Fan out in-app notifications (fire-and-forget, non-critical)
    InAppNotificationService().notifyNoticeCreated(
      noticeId: docRef.id,
      title: title.trim(),
      category: category,
      postedByName: postedByName,
      department: department,
    ).ignore();
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

  /// Real-time stream for a student's feed:
  /// Includes college-wide General ("all") notices + notices for their specific department.
  Stream<List<Notice>> streamStudentFeed(String department) {
    return streamAllNotices().map((notices) => notices
        .where((n) => n.department == 'all' || n.department.toLowerCase() == department.toLowerCase())
        .toList());
  }

  /// Real-time stream strictly for department-specific notices (excludes 'all').
  Stream<List<Notice>> streamDepartmentOnly(String department) {
    return streamAllNotices().map((notices) => notices
        .where((n) => n.department.toLowerCase() == department.toLowerCase())
        .toList());
  }

  /// Real-time stream of only general/college-wide notices.
  Stream<List<Notice>> streamGeneralNotices() {
    return streamAllNotices().map((notices) => notices
        .where((n) => n.department == 'all')
        .toList());
  }

  /// Backward compatible helper
  Stream<List<Notice>> streamNoticesForDepartment(String department) {
    return streamStudentFeed(department);
  }

  Future<void> deleteNotice(String noticeId) async {
    await _noticesRef.doc(noticeId).delete();
  }

  Future<void> updateNotice(String noticeId, Map<String, dynamic> updates) async {
    await _noticesRef.doc(noticeId).update(updates);
  }
}
