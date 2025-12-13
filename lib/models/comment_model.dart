import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String uid;
  final String text;
  final DateTime createdAt;
  final List<String> likes; // Users who liked this comment
  final String? parentCommentId; // For replies (null if top-level comment)
  final DateTime? editedAt; // When comment was last edited

  Comment({
    required this.commentId,
    required this.postId,
    required this.uid,
    required this.text,
    required this.createdAt,
    this.likes = const [],
    this.parentCommentId,
    this.editedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "commentId": commentId,
      "postId": postId,
      "uid": uid,
      "text": text,
      "createdAt": Timestamp.fromDate(createdAt),
      "likes": likes,
      "parentCommentId": parentCommentId,
      "editedAt": editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    // Handle createdAt field - could be Timestamp or already DateTime
    DateTime createdAt;
    if (map["createdAt"] == null) {
      createdAt = DateTime.now();
    } else if (map["createdAt"] is Timestamp) {
      createdAt = (map["createdAt"] as Timestamp).toDate();
    } else if (map["createdAt"] is DateTime) {
      createdAt = map["createdAt"] as DateTime;
    } else {
      // Fallback to current time if unknown type
      createdAt = DateTime.now();
    }

    // Handle editedAt
    DateTime? editedAt;
    if (map["editedAt"] != null) {
      if (map["editedAt"] is Timestamp) {
        editedAt = (map["editedAt"] as Timestamp).toDate();
      } else if (map["editedAt"] is DateTime) {
        editedAt = map["editedAt"] as DateTime;
      }
    }

    return Comment(
      commentId: map["commentId"] ?? "",
      postId: map["postId"] ?? "",
      uid: map["uid"] ?? "",
      text: map["text"] ?? "",
      createdAt: createdAt,
      likes: List<String>.from(map["likes"] ?? []),
      parentCommentId: map["parentCommentId"],
      editedAt: editedAt,
    );
  }
}
