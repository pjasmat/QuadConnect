import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  // Get all users (excluding current user)
  Stream<List<Map<String, dynamic>>> getAllUsers(String excludeUid) {
    return _db
        .collection("users")
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.id != excludeUid) // Filter out current user
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data["uid"] = doc.id;
                return data;
              })
              .toList();
        });
  }
}
