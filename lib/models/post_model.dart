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
      "createdAt": createdAt,
      "likes": likes,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      postId: map["postId"],
      uid: map["uid"],
      content: map["content"],
      imageUrl: map["imageUrl"],
      createdAt: map["createdAt"].toDate(),
      likes: List<String>.from(map["likes"] ?? []),
    );
  }
}
