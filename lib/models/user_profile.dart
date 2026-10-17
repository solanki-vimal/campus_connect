/// Extended profile details, stored separately from AppUser (the
/// auth/routing-critical model in the `users` collection). Lives in its
/// own `profiles/{uid}` collection so growing profile detail never risks
/// the login/role-routing path. Created lazily — may not exist yet for
/// a given user until they first open/edit their Profile screen.
class UserProfile {
  final String uid;
  final String? phone;
  final String? bio;

  // Role-specific fields — only the one relevant to the user's role is
  // ever shown/edited, but all are optional and harmless if unset.
  final String? enrollmentNumber; // Student
  final String? designation; // Faculty, e.g. "Assistant Professor"
  final String? clubPosition; // Club Coordinator, e.g. "President"

  UserProfile({
    required this.uid,
    this.phone,
    this.bio,
    this.enrollmentNumber,
    this.designation,
    this.clubPosition,
  });

  factory UserProfile.empty(String uid) => UserProfile(uid: uid);

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      phone: map['phone'],
      bio: map['bio'],
      enrollmentNumber: map['enrollmentNumber'],
      designation: map['designation'],
      clubPosition: map['clubPosition'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      if (enrollmentNumber != null) 'enrollmentNumber': enrollmentNumber,
      if (designation != null) 'designation': designation,
      if (clubPosition != null) 'clubPosition': clubPosition,
    };
  }

  UserProfile copyWith({
    String? phone,
    String? bio,
    String? enrollmentNumber,
    String? designation,
    String? clubPosition,
  }) {
    return UserProfile(
      uid: uid,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      designation: designation ?? this.designation,
      clubPosition: clubPosition ?? this.clubPosition,
    );
  }
}
