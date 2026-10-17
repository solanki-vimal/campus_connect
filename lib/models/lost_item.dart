import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime? date;
  final String type; // 'lost' | 'found'
  final String postedBy; // uid
  final String postedByName;
  final String contactInfo;
  final bool isResolved;
  final DateTime? createdAt;
  final String? imageUrl; // Firebase Storage download URL (optional)

  LostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.date,
    required this.type,
    required this.postedBy,
    required this.postedByName,
    required this.contactInfo,
    this.isResolved = false,
    this.createdAt,
    this.imageUrl,
  });

  factory LostItem.fromMap(String id, Map<String, dynamic> map) {
    return LostItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Other',
      location: map['location'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate(),
      type: map['type'] ?? 'lost',
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? '',
      contactInfo: map['contactInfo'] ?? '',
      isResolved: map['isResolved'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      if (date != null) 'date': Timestamp.fromDate(date!),
      'type': type,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'contactInfo': contactInfo,
      'isResolved': isResolved,
      'createdAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  LostItem copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? date,
    String? contactInfo,
    bool? isResolved,
    String? imageUrl,
  }) {
    return LostItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      date: date ?? this.date,
      type: type,
      postedBy: postedBy,
      postedByName: postedByName,
      contactInfo: contactInfo ?? this.contactInfo,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
