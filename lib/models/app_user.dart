import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // student | faculty | club_coordinator | super_admin | pending
  final String? requestedRole; // faculty | club_coordinator — only set while role == "pending"
  final String department;
  final String? club;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.requestedRole,
    required this.department,
    this.club,
    this.createdAt,
  });

  bool get isPending => role == 'pending';

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? requestedRole,
    String? department,
    String? club,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      requestedRole: requestedRole ?? this.requestedRole,
      department: department ?? this.department,
      club: club ?? this.club,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      requestedRole: map['requestedRole'],
      department: map['department'] ?? '',
      club: map['club'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
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
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

