import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String category;
  final DateTime? date;
  final String startTime;
  final String endTime;
  final String venue;
  final String organizerId; // uid
  final String organizerName;
  final String organizerType;
  final String department;
  final String? club;
  final bool registrationRequired;
  final int? capacity; // max in-app registrants, null = unlimited
  final DateTime? createdAt;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.date,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.organizerId,
    required this.organizerName,
    required this.organizerType,
    required this.department,
    this.club,
    required this.registrationRequired,
    this.capacity,
    this.createdAt,
  });

  factory Event.fromMap(String id, Map<String, dynamic> map) {
    return Event(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Academic',
      date: (map['date'] as Timestamp?)?.toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      venue: map['venue'] ?? '',
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      organizerType: map['organizerType'] ?? 'faculty',
      department: map['department'] ?? 'all',
      club: map['club'],
      registrationRequired: map['registrationRequired'] ?? false,
      capacity: map['capacity'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      if (date != null) 'date': Timestamp.fromDate(date!),
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerType': organizerType,
      'department': department,
      if (club != null) 'club': club,
      'registrationRequired': registrationRequired,
      if (capacity != null) 'capacity': capacity,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  Event copyWith({
    String? name,
    String? description,
    String? category,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? venue,
    String? department,
    String? club,
    bool? registrationRequired,
    int? capacity,
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerType: organizerType,
      department: department ?? this.department,
      club: club ?? this.club,
      registrationRequired: registrationRequired ?? this.registrationRequired,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt,
    );
  }
}
