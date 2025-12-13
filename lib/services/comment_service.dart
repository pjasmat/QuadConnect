import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_helper.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // Add comment (or reply)
  Future<void> addComment(
    String postId,
    String text, {
    String? parentCommentId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final commentId = _db.collection("comments").doc().id;

    final newComment = Comment(
      commentId: commentId,
      postId: postId,
      uid: uid,
      text: text,
      createdAt: DateTime.now(),
      likes: [],
      parentCommentId: parentCommentId,
    );

    await _db.collection("comments").doc(commentId).set(newComment.toMap());

    // Notify post owner about new comment (only for top-level comments)
    if (parentCommentId == null) {
      final notificationHelper = NotificationHelper();
      await notificationHelper.notifyCommentAdded(postId, text);
    }
  }

  // Edit comment
  Future<void> editComment(String commentId, String newText) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final commentRef = _db.collection("comments").doc(commentId);
    final commentDoc = await commentRef.get();

    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final commentData = commentDoc.data()!;
    if (commentData["uid"] != uid) {
      throw Exception('You can only edit your own comments');
    }

    await commentRef.update({
      "text": newText,
      "editedAt": FieldValue.serverTimestamp(),
    });
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final commentRef = _db.collection("comments").doc(commentId);
    final commentDoc = await commentRef.get();

    if (!commentDoc.exists) {
      throw Exception('Comment not found');
    }

    final commentData = commentDoc.data()!;
    if (commentData["uid"] != uid) {
      throw Exception('You can only delete your own comments');
    }

    // Delete the comment
    await commentRef.delete();

    // Also delete all replies to this comment
    final repliesSnapshot = await _db
        .collection("comments")
        .where("parentCommentId", isEqualTo: commentId)
        .get();

    final batch = _db.batch();
    for (var replyDoc in repliesSnapshot.docs) {
      batch.delete(replyDoc.reference);
    }
    await batch.commit();
  }

  // Toggle like on comment
  Future<void> toggleLike(String commentId, List<String> currentLikes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    final commentRef = _db.collection("comments").doc(commentId);

    if (currentLikes.contains(uid)) {
      await commentRef.update({
        "likes": FieldValue.arrayRemove([uid]),
      });
    } else {
      await commentRef.update({
        "likes": FieldValue.arrayUnion([uid]),
      });
    }
  }

  // Get comments for a post in real time (only top-level comments)
  Stream<List<Comment>> getComments(String postId) {
    return _db
        .collection("comments")
        .where("postId", isEqualTo: postId)
        .snapshots()
        .map((snap) {
          final comments = snap.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  data["commentId"] = doc.id;
                  return Comment.fromMap(data);
                } catch (e) {
                  print("Error parsing comment ${doc.id}: $e");
                  return null;
                }
              })
              .whereType<Comment>()
              // Filter to only top-level comments (no parentCommentId or null)
              .where((comment) => comment.parentCommentId == null)
              .toList();
          // Sort by createdAt ascending (oldest first)
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  // Get replies for a comment
  Stream<List<Comment>> getReplies(String parentCommentId) {
    return _db
        .collection("comments")
        .where("parentCommentId", isEqualTo: parentCommentId)
        .snapshots()
        .map((snap) {
          final replies = snap.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  data["commentId"] = doc.id;
                  return Comment.fromMap(data);
                } catch (e) {
                  print("Error parsing reply ${doc.id}: $e");
                  return null;
                }
              })
              .whereType<Comment>()
              .toList();
          // Sort by createdAt ascending (oldest first)
          replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return replies;
        });
  }
}
