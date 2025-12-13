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
    // Fetch comments and sort client-side to avoid composite index requirement
    return _db
        .collection("comments")
        .where("postId", isEqualTo: postId)
        .snapshots()
        .map((snap) {
          final comments = snap.docs.map((doc) {
            try {
              final data = doc.data();
              data["commentId"] = doc.id;
              return Comment.fromMap(data);
            } catch (e) {
              // Skip invalid comments and log error
              print("Error parsing comment ${doc.id}: $e");
              return null;
            }
          }).whereType<Comment>().toList();
          // Sort by createdAt ascending (oldest first)
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }
}
