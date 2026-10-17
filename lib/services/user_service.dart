import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the Firestore profile document for the given uid.
  /// Returns null if no document exists — the caller (UserProvider) is
  /// responsible for surfacing that as an error, not silently recovering.
  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> createUserDoc(AppUser user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toMap());
  }

  // --- ADMIN METHODS ---

  Stream<List<AppUser>> streamAllUsers() {
    return _firestore.collection('users').orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
    });
  }

  Stream<List<AppUser>> streamPendingUsers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> approveUser(String uid, String requestedRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': requestedRole,
      'requestedRole': FieldValue.delete(),
    });
  }

  Future<void> rejectUser(String uid) async {
    // Deleting the user profile document denies app access
    await _firestore.collection('users').doc(uid).delete();
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}