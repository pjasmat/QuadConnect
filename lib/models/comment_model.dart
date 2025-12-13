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
      "createdAt": createdAt,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map["commentId"],
      postId: map["postId"],
      uid: map["uid"],
      text: map["text"],
      createdAt: map["createdAt"].toDate(),
    );
  }
}
