import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const String allowedDomain = 'ddu.ac.in';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  bool isCollegeEmail(String email) {
    return email.trim().toLowerCase().endsWith('@$allowedDomain');
  }

  /// Creates an account for Student (immediately active) or Faculty/Club
  /// Coordinator (goes into "pending" state until Super Admin approves).
  /// Super Admin accounts are never created through this method.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String department,
    required String selectedRole, // 'student' | 'faculty' | 'club_coordinator'
    String? club, // only used when selectedRole == 'club_coordinator'
  }) async {
    if (!isCollegeEmail(email)) {
      return 'Only @$allowedDomain email addresses are allowed to sign up.';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(name.trim());

      final bool isSelfServiceRole = selectedRole == 'faculty' || selectedRole == 'club_coordinator';

      await _firestore.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        // Student accounts are active immediately. Faculty/Club Coordinator
        // requests go into "pending" until a Super Admin approves them —
        // they never get real access under the requested role automatically.
        'role': isSelfServiceRole ? 'pending' : 'student',
        if (isSelfServiceRole) 'requestedRole': selectedRole,
        'department': department,
        if (selectedRole == 'club_coordinator' && club != null && club.isNotEmpty) 'club': club,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Signup failed. Please try again.';
    } catch (e) {
      return 'Signup failed: $e';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed. Please check your credentials.';
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
