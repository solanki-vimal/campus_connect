import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generic method to stream names from a collection (documents must have a 'name' field)
  Stream<List<String>> streamNames(String collectionPath) {
    return _firestore.collection(collectionPath).orderBy('name').snapshots().map((snap) {
      return snap.docs.map((d) => d.data()['name'] as String).toList();
    });
  }

  /// Generic method to add a name to a collection
  Future<void> addName(String collectionPath, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final existing = await _firestore
        .collection(collectionPath)
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _firestore.collection(collectionPath).add({
        'name': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Generic method to update/rename an item in a collection
  Future<void> updateName(String collectionPath, String oldName, String newName) async {
    final trimmedNew = newName.trim();
    if (trimmedNew.isEmpty || oldName == trimmedNew) return;

    final snap = await _firestore.collection(collectionPath).where('name', isEqualTo: oldName).get();
    for (var doc in snap.docs) {
      await doc.reference.update({'name': trimmedNew});
    }
  }

  /// Generic method to delete a name from a collection
  Future<void> deleteName(String collectionPath, String name) async {
    final snap = await _firestore.collection(collectionPath).where('name', isEqualTo: name).get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
