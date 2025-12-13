import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import '../services/post_service.dart';
import '../services/event_service.dart';
import '../widgets/feed_item.dart';
import '../widgets/skeleton_loader.dart';
import 'create_post_page.dart';
import 'notifications_page.dart';

class FeedPage extends StatelessWidget {
  FeedPage({super.key});

  final PostService _postService = PostService();
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: StreamBuilder<QuerySnapshot>(
          stream: FirebaseAuth.instance.currentUser != null
              ? FirebaseFirestore.instance
                    .collection('notifications')
                    .where(
                      'userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .snapshots()
              : Stream<QuerySnapshot>.empty(),
          builder: (context, snapshot) {
            // Count unread notifications client-side
            final unreadCount = snapshot.hasData && snapshot.data != null
                ? snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['isRead'] ?? false) == false;
                  }).length
                : 0;
            return IconButton(
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                );
              },
            );
          },
        ),
        title: const Text(
          "QuadConnect",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Post>>(
          stream: _postService.getPosts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error loading posts: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              // Show skeleton loaders
              return ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: 5,
                itemBuilder: (context, index) => const SkeletonPostCard(),
              );
            }

            final posts = snapshot.data!;

            // Get upcoming events (within next 7 days)
            return StreamBuilder<List<EventModel>>(
              stream: _eventService.getEvents(),
              builder: (context, eventsSnapshot) {
                List<dynamic> feedItems = [];

                // Add upcoming events (next 7 days)
                if (eventsSnapshot.hasData) {
                  final now = DateTime.now();
                  final weekFromNow = now.add(const Duration(days: 7));
                  final upcomingEvents = eventsSnapshot.data!
                      .where(
                        (e) =>
                            e.date.isAfter(now) && e.date.isBefore(weekFromNow),
                      )
                      .take(3) // Limit to 3 upcoming events
                      .toList();
                  feedItems.addAll(upcomingEvents);
                }

                // Add all posts
                feedItems.addAll(posts);

                // Sort by date (newest first for posts, soonest first for events)
                feedItems.sort((a, b) {
                  if (a is EventModel && b is EventModel) {
                    return a.date.compareTo(b.date);
                  } else if (a is Post && b is Post) {
                    return b.createdAt.compareTo(a.createdAt);
                  } else if (a is EventModel && b is Post) {
                    // Events come before posts
                    return -1;
                  } else {
                    return 1;
                  }
                });

                if (feedItems.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No posts or events yet",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Trigger refresh by rebuilding the stream
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: feedItems.length,
                    itemBuilder: (context, index) {
                      final item = feedItems[index];
                      try {
                        return FeedItem(item: item, isPost: item is Post);
                      } catch (e) {
                        // Skip invalid items
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
