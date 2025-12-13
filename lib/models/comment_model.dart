import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String uid;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.commentId,
    required this.postId,
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "commentId": commentId,
      "postId": postId,
      "uid": uid,
      "text": text,
      "createdAt": Timestamp.fromDate(createdAt),
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
    
    return Comment(
      commentId: map["commentId"] ?? "",
      postId: map["postId"] ?? "",
      uid: map["uid"] ?? "",
      text: map["text"] ?? "",
      createdAt: createdAt,
    );
  }
}
