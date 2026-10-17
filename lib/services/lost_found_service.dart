import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_item.dart';

class LostFoundService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('lost_found');

  /// Stream of all lost items, newest first, excluding resolved.
  Stream<List<LostItem>> streamLostItems() {
    return _ref
        .where('type', isEqualTo: 'lost')
        .where('isResolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LostItem.fromMap(d.id, d.data())).toList());
  }

  /// Stream of all found items, newest first, excluding resolved.
  Stream<List<LostItem>> streamFoundItems() {
    return _ref
        .where('type', isEqualTo: 'found')
        .where('isResolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LostItem.fromMap(d.id, d.data())).toList());
  }

  /// Stream of items posted by a specific user.
  Stream<List<LostItem>> streamMyItems(String uid) {
    return _ref
        .where('postedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => LostItem.fromMap(d.id, d.data())).toList());
  }

  /// Creates a new lost or found report.
  Future<void> createItem({
    required String title,
    required String description,
    required String category,
    required String location,
    required DateTime date,
    required String type,
    required String postedBy,
    required String postedByName,
    required String contactInfo,
    String? imageUrl, // optional — set if user uploaded a photo
  }) async {
    await _ref.add({
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'location': location.trim(),
      'date': Timestamp.fromDate(date),
      'type': type,
      'postedBy': postedBy,
      'postedByName': postedByName,
      'contactInfo': contactInfo.trim(),
      'isResolved': false,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    });
  }

  /// Marks an item as resolved (found/returned).
  Future<void> markResolved(String itemId) async {
    await _ref.doc(itemId).update({'isResolved': true});
  }

  /// Deletes a lost/found report.
  Future<void> deleteItem(String itemId) async {
    await _ref.doc(itemId).delete();
  }
}
