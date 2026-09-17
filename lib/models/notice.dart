import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String description;
  final String category; // Academic | Examination | Holiday | Placement | Workshop | Fee/Admin | Emergency | General
  final String department; // a real department, or "all" for general/college-wide notices
  final String priority; // normal | important | urgent
  final String postedBy; // uid
  final String postedByName;
  final DateTime? datePosted;
  final DateTime? expiryDate; // optional — null means no expiry

  Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.department,
    required this.priority,
    required this.postedBy,
    required this.postedByName,
    this.datePosted,
    this.expiryDate,
  });

  factory Notice.fromMap(String id, Map<String, dynamic> map) {
    return Notice(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'General',
      department: map['department'] ?? 'all',
      priority: map['priority'] ?? 'normal',
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? '',
      datePosted: (map['datePosted'] as Timestamp?)?.toDate(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'department': department,
      'priority': priority,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'datePosted': datePosted != null ? Timestamp.fromDate(datePosted!) : FieldValue.serverTimestamp(),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
    };
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  Notice copyWith({
    String? title,
    String? description,
    String? category,
    String? department,
    String? priority,
    DateTime? expiryDate,
  }) {
    return Notice(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      department: department ?? this.department,
      priority: priority ?? this.priority,
      postedBy: postedBy,
      postedByName: postedByName,
      datePosted: datePosted,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}
