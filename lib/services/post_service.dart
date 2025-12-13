import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'notification_helper.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // CREATE POST
  Future<void> createPost(
    String content, {
    String? imageUrl,
    String? videoUrl,
    String? backgroundColor,
    bool isPublic = true,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final postId = _db.collection("posts").doc().id;

    final newPost = Post(
      postId: postId,
      uid: uid,
      content: content,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      backgroundColor: backgroundColor,
      createdAt: DateTime.now(),
      likes: [],
      isPublic: isPublic,
    );

    final postMap = newPost.toMap();
    // Ensure postId is in the map (it should be, but double-check)
    postMap["postId"] = postId;

    // Remove null values to avoid storing them in Firestore
    postMap.removeWhere((key, value) => value == null);

    await _db.collection("posts").doc(postId).set(postMap);

    // Notify followers about new post
    final notificationHelper = NotificationHelper();
    await notificationHelper.notifyNewPost(postId, content);
  }

  // UPDATE POST
  Future<void> updatePost(
    String postId,
    String content, {
    String? imageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final postRef = _db.collection("posts").doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw Exception('Post not found');
    }

    final postData = postDoc.data()!;
    if (postData["uid"] != uid) {
      throw Exception('You can only edit your own posts');
    }

    await postRef.update({
      "content": content,
      if (imageUrl != null) "imageUrl": imageUrl,
    });
  }

  // DELETE POST
  Future<void> deletePost(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (postId.isEmpty) {
      throw Exception('Invalid post ID');
    }

    try {
      // Use the postId directly as document ID
      final postRef = _db.collection("posts").doc(postId);

      // Check if document exists and verify ownership
      final postDoc = await postRef.get();

      if (!postDoc.exists) {
        throw Exception('Post not found with ID: $postId');
      }

      final postData = postDoc.data();
      if (postData == null) {
        throw Exception('Post data is null');
      }

      final postUid = postData["uid"] as String?;
      if (postUid == null) {
        throw Exception('Post does not have a uid field');
      }

      if (postUid != uid) {
        throw Exception(
          'You can only delete your own posts. Post owner: $postUid, Current user: $uid',
        );
      }

      // Delete the document
      await postRef.delete();
    } catch (e) {
      // Re-throw with more context for debugging
      if (e.toString().contains('Exception')) {
        rethrow;
      }
      throw Exception('Failed to delete post: $e');
    }
  }

  // TOGGLE POST VISIBILITY (Public/Private)
  Future<void> togglePostVisibility(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final postRef = _db.collection("posts").doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw Exception('Post not found');
    }

    final postData = postDoc.data()!;
    if (postData["uid"] != uid) {
      throw Exception('You can only change visibility of your own posts');
    }

    final currentVisibility = postData["isPublic"] ?? true;
    await postRef.update({"isPublic": !currentVisibility});
  }

  // LIKE / UNLIKE
  Future<void> toggleLike(String postId, List likes) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final wasLiked = likes.contains(uid);

    if (wasLiked) {
      await _db.collection("posts").doc(postId).update({
        "likes": FieldValue.arrayRemove([uid]),
      });
    } else {
      await _db.collection("posts").doc(postId).update({
        "likes": FieldValue.arrayUnion([uid]),
      });

      // Get post owner and notify
      try {
        final postDoc = await _db.collection("posts").doc(postId).get();
        if (postDoc.exists) {
          final postData = postDoc.data()!;
          final ownerId = postData['uid'] as String?;
          if (ownerId != null && ownerId != uid) {
            final notificationHelper = NotificationHelper();
            await notificationHelper.notifyPostLiked(postId, ownerId);
          }
        }
      } catch (e) {
        // Log error but don't fail the like operation
        print('Error sending like notification: $e');
      }
    }
  }

  // REAL-TIME POSTS STREAM
  Stream<List<Post>> getPosts() {
    return _db
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  // Ensure we have the document ID in the data
                  data["postId"] = doc.id;
                  return Post.fromMap(data);
                } catch (e) {
                  // Skip invalid posts; consider logging in debug builds
                  return null;
                }
              })
              .whereType<Post>()
              .toList();
          return posts;
        });
  }

  Stream<List<Post>> getPaginatedPosts(DocumentSnapshot? lastDoc, int limit) {
    Query<Map<String, dynamic>> query = _db
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .limit(limit);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data["postId"] = doc.id;
              return Post.fromMap(data);
            } catch (e) {
              // Skip invalid posts; consider logging in debug builds
              return null;
            }
          })
          .whereType<Post>()
          .toList();
      return posts;
    });
  }

  Stream<List<Post>> getPostsByUser(String uid) {
    // Fetch posts and sort client-side to avoid composite index requirement
    return _db.collection("posts").where("uid", isEqualTo: uid).snapshots().map(
      (snap) {
        final posts = snap.docs
            .map((doc) {
              try {
                final data = doc.data();
                data["postId"] = doc.id;
                return Post.fromMap(data);
              } catch (e) {
                // Skip invalid posts; consider logging in debug builds
                return null;
              }
            })
            .whereType<Post>()
            .toList();
        // Sort by createdAt descending (newest first)
        posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return posts;
      },
    );
  }
}
