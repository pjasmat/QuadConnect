import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';

class SearchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Search users by username or name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final usersSnapshot = await _db.collection('users').get();

    return usersSnapshot.docs
        .map((doc) {
          final data = doc.data();
          data['uid'] = doc.id;
          return data;
        })
        .where((user) {
          final username = (user['username'] ?? '').toString().toLowerCase();
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          return username.contains(queryLower) ||
              name.contains(queryLower) ||
              email.contains(queryLower);
        })
        .toList();
  }

  // Search posts by content (only public posts)
  Future<List<Post>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final postsSnapshot = await _db.collection('posts').get();

    return postsSnapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            data['postId'] = doc.id;
            return Post.fromMap(data);
          } catch (e) {
            return null;
          }
        })
        .whereType<Post>()
        .where((post) {
          // Only show public posts in search
          return post.isPublic &&
              post.content.toLowerCase().contains(queryLower);
        })
        .toList();
  }

  // Search events by title, description, or location
  Future<List<EventModel>> searchEvents(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final eventsSnapshot = await _db.collection('events').get();

    return eventsSnapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            data['eventId'] = doc.id;
            return EventModel.fromMap(data);
          } catch (e) {
            return null;
          }
        })
        .whereType<EventModel>()
        .where((event) {
          return event.title.toLowerCase().contains(queryLower) ||
              event.description.toLowerCase().contains(queryLower) ||
              event.location.toLowerCase().contains(queryLower);
        })
        .toList();
  }

  // Combined search (users, posts, events)
  Future<Map<String, dynamic>> searchAll(String query) async {
    if (query.isEmpty) {
      return {
        'users': <Map<String, dynamic>>[],
        'posts': <Post>[],
        'events': <EventModel>[],
      };
    }

    final results = await Future.wait([
      searchUsers(query),
      searchPosts(query),
      searchEvents(query),
    ]);

    return {
      'users': results[0] as List<Map<String, dynamic>>,
      'posts': results[1] as List<Post>,
      'events': results[2] as List<EventModel>,
    };
  }
}
