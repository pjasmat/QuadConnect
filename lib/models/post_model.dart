import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> likes;

  Post({
    required this.postId,
    required this.uid,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    required this.likes,
  });

  Map<String, dynamic> toMap() {
    return {
      "postId": postId,
      "uid": uid,
      "content": content,
      "imageUrl": imageUrl,
      "createdAt": Timestamp.fromDate(createdAt),
      "likes": likes,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
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
    
    return Post(
      postId: map["postId"] ?? "",
      uid: map["uid"] ?? "",
      content: map["content"] ?? "",
      imageUrl: map["imageUrl"],
      createdAt: createdAt,
      likes: List<String>.from(map["likes"] ?? []),
    );
  }
}
