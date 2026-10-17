import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Reads/writes the `profiles` collection only — never touches `users`
/// (AppUser), keeping profile detail edits completely separate from the
/// auth/role-routing data path.
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _profilesRef =>
      _firestore.collection('profiles');

  Future<UserProfile> fetchProfile(String uid) async {
    final doc = await _profilesRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return UserProfile.empty(uid);
    }
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _profilesRef.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }
}
