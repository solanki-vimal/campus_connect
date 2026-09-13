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
}