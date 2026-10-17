import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored at events/{eventId}/registrations/{uid} — doc id IS the user's
/// uid, which naturally prevents duplicate registrations (a second
/// registerForEvent call just overwrites the same doc).
class EventRegistration {
  final String uid;
  final String userName;
  final String userEmail;
  final DateTime? registeredAt;

  EventRegistration({
    required this.uid,
    required this.userName,
    required this.userEmail,
    this.registeredAt,
  });

  factory EventRegistration.fromMap(String uid, Map<String, dynamic> map) {
    return EventRegistration(
      uid: uid,
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      registeredAt: (map['registeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'registeredAt': FieldValue.serverTimestamp(),
    };
  }
}
