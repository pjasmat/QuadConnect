import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // CREATE POST
  Future<void> createPost(String content, {String? imageUrl}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final postId = _db.collection("posts").doc().id;

    final newPost = Post(
      postId: postId,
      uid: uid,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      likes: [],
    );

    await _db.collection("posts").doc(postId).set(newPost.toMap());
  }

  // LIKE / UNLIKE
  Future<void> toggleLike(String postId, List likes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    if (likes.contains(uid)) {
      await _db.collection("posts").doc(postId).update({
        "likes": FieldValue.arrayRemove([uid])
      });
    } else {
      await _db.collection("posts").doc(postId).update({
        "likes": FieldValue.arrayUnion([uid])
      });
    }
  }

  // REAL-TIME POSTS STREAM
  Stream<List<Post>> getPosts() {
    return _db
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Post>> getPaginatedPosts(DocumentSnapshot? lastDoc, int limit) {
    Query<Map<String, dynamic>> query = _db
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromMap(doc.data())).toList(),
        );
  }

  Stream<List<Post>> getPostsByUser(String uid) {
    return _db
        .collection("posts")
        .where("uid", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Post.fromMap(doc.data())).toList(),
        );
  }
}
