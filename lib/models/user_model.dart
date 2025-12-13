class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final String bio;
  final List<String> followers;
  final List<String> following;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    this.bio = "",
    this.followers = const [],
    this.following = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "username": username,
      "email": email,
      "photoUrl": photoUrl,
      "bio": bio,
      "followers": followers,
      "following": following,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map["uid"],
      username: map["username"] ?? "",
      email: map["email"] ?? "",
      photoUrl: map["photoUrl"],
      bio: map["bio"] ?? "",
      followers: List<String>.from(map["followers"] ?? []),
      following: List<String>.from(map["following"] ?? []),
    );
  }
}
