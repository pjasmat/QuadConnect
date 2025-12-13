import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationHelper {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? senderId,
    String? postId,
    String? eventId,
    String? commentId,
  }) async {
    // Don't notify yourself
    final currentUid = _auth.currentUser?.uid;
    if (userId == currentUid) return;

    final notificationId = _db.collection('notifications').doc().id;

    await _db.collection('notifications').doc(notificationId).set({
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'senderId': senderId ?? currentUid,
      'postId': postId,
      'eventId': eventId,
      'commentId': commentId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create notification for post like
  Future<void> notifyPostLiked(String postId, String postOwnerId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    // Don't notify if liking your own post
    if (postOwnerId == currentUid) return;

    try {
      // Get current user info
      final userDoc = await _db.collection('users').doc(currentUid).get();
      if (!userDoc.exists) return;
      
      final userName = userDoc.data()?['username'] ?? 
                       userDoc.data()?['name'] ?? 
                       'Someone';

      // Get post content for notification body
      final postDoc = await _db.collection('posts').doc(postId).get();
      final postContent = postDoc.exists 
          ? (postDoc.data()?['content']?.toString() ?? '')
          : '';

      await createNotification(
        userId: postOwnerId,
        type: 'like',
        title: '$userName liked your post',
        body: postContent.length > 50 
            ? '${postContent.substring(0, 50)}...' 
            : postContent,
        senderId: currentUid,
        postId: postId,
      );
    } catch (e) {
      print('Error creating like notification: $e');
    }
  }

  // Create notification for comment
  Future<void> notifyCommentAdded(String postId, String commentText) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // Get post owner info
      final postDoc = await _db.collection('posts').doc(postId).get();
      if (!postDoc.exists) return;

      final postData = postDoc.data()!;
      final ownerId = postData['uid'] as String?;
      
      // Don't notify if commenting on your own post
      if (ownerId == null || ownerId == currentUid) return;

      // Get current user info
      final userDoc = await _db.collection('users').doc(currentUid).get();
      if (!userDoc.exists) return;
      
      final userName = userDoc.data()?['username'] ?? 
                       userDoc.data()?['name'] ?? 
                       'Someone';

      await createNotification(
        userId: ownerId,
        type: 'comment',
        title: '$userName commented on your post',
        body: commentText.length > 50 
            ? '${commentText.substring(0, 50)}...' 
            : commentText,
        senderId: currentUid,
        postId: postId,
      );
    } catch (e) {
      print('Error creating comment notification: $e');
    }
  }

  // Create notification for new post (notify followers)
  Future<void> notifyNewPost(String postId, String postContent) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    // Get current user info
    final userDoc = await _db.collection('users').doc(currentUid).get();
    final userName = userDoc.data()?['username'] ?? userDoc.data()?['name'] ?? 'Someone';
    final followers = userDoc.data()?['followers'] as List<dynamic>? ?? [];

    // Notify all followers
    for (var followerId in followers) {
      if (followerId is String && followerId != currentUid) {
        await createNotification(
          userId: followerId,
          type: 'post',
          title: '$userName created a new post',
          body: postContent.length > 50 ? '${postContent.substring(0, 50)}...' : postContent,
          senderId: currentUid,
          postId: postId,
        );
      }
    }
  }

  // Create notification for new event (notify all users)
  Future<void> notifyNewEvent(String eventId, String eventTitle) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    try {
      // Get current user info
      final userDoc = await _db.collection('users').doc(currentUid).get();
      if (!userDoc.exists) return;
      
      final userName = userDoc.data()?['username'] ?? 
                       userDoc.data()?['name'] ?? 
                       'Someone';

      // Get all users from Firestore
      final allUsersSnapshot = await _db.collection('users').get();
      
      // Notify all users (except the event creator)
      for (var userDoc in allUsersSnapshot.docs) {
        final userId = userDoc.id;
        
        // Skip notifying the event creator
        if (userId == currentUid) continue;
        
        try {
          await createNotification(
            userId: userId,
            type: 'event',
            title: '$userName created a new event',
            body: eventTitle.length > 50 
                ? '${eventTitle.substring(0, 50)}...' 
                : eventTitle,
            senderId: currentUid,
            eventId: eventId,
          );
        } catch (e) {
          // Continue with other users even if one fails
          print('Error notifying user $userId: $e');
        }
      }
    } catch (e) {
      print('Error creating event notifications: $e');
    }
  }

  // Create notification for post share
  Future<void> notifyPostShared(String postId, String postOwnerId) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    // Don't notify if sharing your own post
    if (postOwnerId == currentUid) return;

    try {
      // Get current user info
      final userDoc = await _db.collection('users').doc(currentUid).get();
      if (!userDoc.exists) return;
      
      final userName = userDoc.data()?['username'] ?? 
                       userDoc.data()?['name'] ?? 
                       'Someone';

      // Get post content for notification body
      final postDoc = await _db.collection('posts').doc(postId).get();
      final postContent = postDoc.exists 
          ? (postDoc.data()?['content']?.toString() ?? '')
          : '';

      await createNotification(
        userId: postOwnerId,
        type: 'share',
        title: '$userName shared your post',
        body: postContent.length > 50 
            ? '${postContent.substring(0, 50)}...' 
            : postContent,
        senderId: currentUid,
        postId: postId,
      );
    } catch (e) {
      print('Error creating share notification: $e');
    }
  }
}

