import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add comment
  Future<void> addComment(String postId, String text) async {
    String uid = _auth.currentUser!.uid;
    String commentId = _db.collection("comments").doc().id;

    Comment newComment = Comment(
      commentId: commentId,
      postId: postId,
      uid: uid,
      text: text,
      createdAt: DateTime.now(),
    );

    await _db.collection("comments").doc(commentId).set(newComment.toMap());
  }

  // Get comments for a post in real time
  Stream<List<Comment>> getComments(String postId) {
    return _db
        .collection("comments")
        .where("postId", isEqualTo: postId)
        .orderBy("createdAt", descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Comment.fromMap(doc.data()))
            .toList());
  }
}
