import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String content;
  final String? imageUrl;
  final String? videoUrl; // Video URL for video posts
  final String? backgroundColor; // Background color for text posts (hex color)
  final DateTime createdAt;
  final List<String> likes;
  final bool isPublic; // true = public, false = private

  Post({
    required this.postId,
    required this.uid,
    required this.content,
    required this.createdAt,
    this.imageUrl,
    this.videoUrl,
    this.backgroundColor,
    required this.likes,
    this.isPublic = true, // Default to public
  });

  Map<String, dynamic> toMap() {
    return {
      "postId": postId,
      "uid": uid,
      "content": content,
      "imageUrl": imageUrl,
      "videoUrl": videoUrl,
      "backgroundColor": backgroundColor,
      "createdAt": Timestamp.fromDate(createdAt),
      "likes": likes,
      "isPublic": isPublic,
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

    // Handle imageUrl, videoUrl, backgroundColor - convert empty strings to null
    String? imageUrl = map["imageUrl"];
    if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;

    String? videoUrl = map["videoUrl"];
    if (videoUrl != null && videoUrl.isEmpty) videoUrl = null;

    String? backgroundColor = map["backgroundColor"];
    if (backgroundColor != null && backgroundColor.isEmpty)
      backgroundColor = null;

    return Post(
      postId: map["postId"] ?? "",
      uid: map["uid"] ?? "",
      content: map["content"] ?? "",
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      backgroundColor: backgroundColor,
      createdAt: createdAt,
      likes: List<String>.from(map["likes"] ?? []),
      isPublic: map["isPublic"] ?? true, // Default to public if not set
    );
  }
}
