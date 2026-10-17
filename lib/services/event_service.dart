import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import 'in_app_notification_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsRef =>
      _firestore.collection('events');

  CollectionReference<Map<String, dynamic>> _registrationsRef(String eventId) =>
      _eventsRef.doc(eventId).collection('registrations');

  /// Creates and immediately publishes a new event, then fans out
  /// an in-app notification to every active user.
  Future<void> createEvent({
    required String name,
    required String description,
    required String category,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String venue,
    required String organizerId,
    required String organizerName,
    required String organizerType,
    required String department,
    String? club,
    required bool registrationRequired,
    int? capacity,
  }) async {
    final docRef = await _eventsRef.add({
      'name': name.trim(),
      'description': description.trim(),
      'category': category,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue.trim(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerType': organizerType,
      'department': department,
      if (club != null && club.isNotEmpty) 'club': club,
      'registrationRequired': registrationRequired,
      'capacity': capacity,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Fan out in-app notifications (fire-and-forget, non-critical)
    InAppNotificationService().notifyEventCreated(
      eventId: docRef.id,
      name: name.trim(),
      venue: venue.trim(),
      organizerName: organizerName,
    ).ignore();
  }

  /// All published events, sorted by date ascending.
  Stream<List<Event>> streamEvents() {
    return _eventsRef.snapshots().map((snap) {
      final events =
          snap.docs.map((d) => Event.fromMap(d.id, d.data())).toList();
      events.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });
      return events;
    });
  }

  /// An organizer's own events — lets Faculty/Club Coordinator see the
  /// events they created, sorted newest first.
  Stream<List<Event>> streamMyEvents(String organizerId) {
    return _eventsRef
        .where('organizerId', isEqualTo: organizerId)
        .snapshots()
        .map((snap) {
      final events =
          snap.docs.map((d) => Event.fromMap(d.id, d.data())).toList();
      events.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return events;
    });
  }

  Future<void> updateEvent(
      String eventId, Map<String, dynamic> updates) async {
    await _eventsRef.doc(eventId).update(updates);
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsRef.doc(eventId).delete();
  }

  // ---- In-app registration ----

  /// Registers [uid] for [eventId]. Throws if the event is at capacity.
  /// Uses a transaction so two simultaneous registrations near the
  /// capacity limit can't both squeeze in past it.
  Future<void> registerForEvent({
    required String eventId,
    required String uid,
    required String userName,
    required String userEmail,
    int? capacity,
  }) async {
    final regRef = _registrationsRef(eventId).doc(uid);

    await _firestore.runTransaction((transaction) async {
      if (capacity != null) {
        final countSnap = await _registrationsRef(eventId).count().get();
        final current = countSnap.count ?? 0;
        if (current >= capacity) {
          throw Exception('This event is full');
        }
      }
      transaction.set(regRef, {
        'userName': userName,
        'userEmail': userEmail,
        'registeredAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> unregisterFromEvent(String eventId, String uid) async {
    await _registrationsRef(eventId).doc(uid).delete();
  }

  /// Whether [uid] is currently registered for [eventId], live-updating.
  Stream<bool> streamIsRegistered(String eventId, String uid) {
    return _registrationsRef(eventId).doc(uid).snapshots().map((doc) => doc.exists);
  }

  /// Live registrant count for an event.
  Stream<int> streamRegistrationCount(String eventId) {
    return _registrationsRef(eventId).snapshots().map((snap) => snap.docs.length);
  }

  /// Full list of registrants — for the organizer/Admin to view.
  Stream<List<EventRegistration>> streamRegistrants(String eventId) {
    return _registrationsRef(eventId).snapshots().map((snap) {
      final regs = snap.docs
          .map((d) => EventRegistration.fromMap(d.id, d.data()))
          .toList();
      regs.sort((a, b) {
        if (a.registeredAt == null && b.registeredAt == null) return 0;
        if (a.registeredAt == null) return 1;
        if (b.registeredAt == null) return -1;
        return a.registeredAt!.compareTo(b.registeredAt!);
      });
      return regs;
    });
  }
}
