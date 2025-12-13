class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final String bio;
  final List<String> followers;
  final List<String> following;
  final String? website;
  final String? linkedin;
  final String? instagram;
  final String? twitter;
  final String? github;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    this.bio = "",
    this.followers = const [],
    this.following = const [],
    this.website,
    this.linkedin,
    this.instagram,
    this.twitter,
    this.github,
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
      "website": website,
      "linkedin": linkedin,
      "instagram": instagram,
      "twitter": twitter,
      "github": github,
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
      website: map["website"],
      linkedin: map["linkedin"],
      instagram: map["instagram"],
      twitter: map["twitter"],
      github: map["github"],
    );
  }
}
