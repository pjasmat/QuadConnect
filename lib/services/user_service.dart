import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final CollectionReference users =
      FirebaseFirestore.instance.collection("users");

  // Get raw user map once
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await users.doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  // Get user as stream
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return users.doc(uid).snapshots();
  }

  // Get AppUser as stream
  Stream<AppUser> getUserModelStream(String uid) {
    return users.doc(uid).snapshots().map((doc) {
      return AppUser.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // Get user once
  Future<DocumentSnapshot> getUserOnce(String uid) {
    return users.doc(uid).get();
  }

  // Create user document
  Future<void> createUser(AppUser user) async {
    await users.doc(user.uid).set(user.toMap());
  }

  // Update profile
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await users.doc(uid).update(data);
  }

  // FOLLOW user
  Future<void> followUser(String currentUid, String targetUid) async {
    await users.doc(targetUid).update({
      "followers": FieldValue.arrayUnion([currentUid])
    });

    await users.doc(currentUid).update({
      "following": FieldValue.arrayUnion([targetUid])
    });
  }

  // UNFOLLOW
  Future<void> unfollowUser(String currentUid, String targetUid) async {
    await users.doc(targetUid).update({
      "followers": FieldValue.arrayRemove([currentUid])
    });

    await users.doc(currentUid).update({
      "following": FieldValue.arrayRemove([targetUid])
    });
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
