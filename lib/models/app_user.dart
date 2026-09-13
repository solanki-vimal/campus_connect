class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // student | faculty | club_coordinator | super_admin | pending
  final String? requestedRole; // faculty | club_coordinator — only set while role == "pending"
  final String department;
  final String? club;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.requestedRole,
    required this.department,
    this.club,
  });

  bool get isPending => role == 'pending';

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      requestedRole: map['requestedRole'],
      department: map['department'] ?? '',
      club: map['club'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (requestedRole != null) 'requestedRole': requestedRole,
      'department': department,
      if (club != null) 'club': club,
    };
  }
}
