import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';
import '../services/event_service.dart';
import 'post_detail_page.dart';
import 'event_details_page.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:convert';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Clear All button
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: currentUid)
                .snapshots(),
            builder: (context, snapshot) {
              final hasNotifications = snapshot.hasData && 
                  snapshot.data!.docs.isNotEmpty;
              
              if (!hasNotifications) {
                return const SizedBox.shrink();
              }
              
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'clear_all') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Notifications'),
                        content: const Text(
                          'Are you sure you want to delete all notifications? This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      try {
                        final notifications = await FirebaseFirestore.instance
                            .collection('notifications')
                            .where('userId', isEqualTo: currentUid)
                            .get();

                        final batch = FirebaseFirestore.instance.batch();
                        for (var doc in notifications.docs) {
                          batch.delete(doc.reference);
                        }
                        await batch.commit();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications cleared'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error clearing notifications: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          // Sort by createdAt descending (newest first) - client-side to avoid index
          final sortedNotifications = notifications.toList()
            ..sort((a, b) {
              final aTime =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final bTime =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // Descending
            });

          if (sortedNotifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedNotifications.length,
            itemBuilder: (context, index) {
              final notification =
                  sortedNotifications[index].data() as Map<String, dynamic>;
              final notificationId = sortedNotifications[index].id;
              final isRead = notification['isRead'] ?? false;
              final type = notification['type'] ?? 'general';
              final title = notification['title'] ?? 'Notification';
              final body = notification['body'] ?? '';
              final createdAt =
                  (notification['createdAt'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final senderId = notification['senderId'] as String?;

              final postId = notification['postId'] as String?;
              final eventId = notification['eventId'] as String?;

              return _buildNotificationTile(
                context,
                notificationId: notificationId,
                type: type,
                title: title,
                body: body,
                createdAt: createdAt,
                isRead: isRead,
                senderId: senderId,
                postId: postId,
                eventId: eventId,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String notificationId,
    required String type,
    required String title,
    required String body,
    required DateTime createdAt,
    required bool isRead,
    String? senderId,
    String? postId,
    String? eventId,
  }) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'like':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.comment;
        iconColor = Colors.blue;
        break;
      case 'message':
        icon = Icons.message;
        iconColor = Colors.green;
        break;
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.purple;
        break;
      case 'post':
        icon = Icons.post_add;
        iconColor = Colors.orange;
        break;
      case 'event':
        icon = Icons.event;
        iconColor = Colors.purple;
        break;
      case 'share':
        icon = Icons.share;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: senderId != null
          ? UserService().getUser(senderId)
          : Future.value(null),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final profilePic = user?["photoUrl"] ?? user?["profilePicUrl"] ?? "";

        return Dismissible(
          key: Key(notificationId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            FirebaseFirestore.instance
                .collection('notifications')
                .doc(notificationId)
                .delete();
          },
          child: InkWell(
            onTap: () async {
              // Mark as read
              if (!isRead) {
                FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(notificationId)
                    .update({'isRead': true});
              }

              // Navigate based on type
              if (postId != null) {
                // Navigate to post detail
                try {
                  final postService = PostService();
                  final postStream = postService.getPosts();
                  final postsSnapshot = await postStream.first;
                  final post = postsSnapshot.firstWhere(
                    (p) => p.postId == postId,
                    orElse: () => postsSnapshot.first,
                  );

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(
                          post: post,
                          allPosts: postsSnapshot,
                          initialIndex: postsSnapshot.indexOf(post),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Post not found: $e')),
                    );
                  }
                }
              } else if (eventId != null) {
                // Navigate to event detail
                try {
                  final eventService = EventService();
                  final eventsStream = eventService.getEvents();
                  final eventsSnapshot = await eventsStream.first;
                  final event = eventsSnapshot.firstWhere(
                    (e) => e.eventId == eventId,
                  );

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsPage(event: event),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Event not found: $e')),
                    );
                  }
                }
              }
            },
            child: Container(
              color: isRead ? Colors.transparent : Colors.blue.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture or icon
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: iconColor.withOpacity(0.2),
                    backgroundImage: profilePic.isNotEmpty
                        ? (profilePic.startsWith('data:image/')
                              ? MemoryImage(
                                  base64Decode(profilePic.split(',')[1]),
                                )
                              : NetworkImage(profilePic))
                        : null,
                    child: profilePic.isEmpty
                        ? Icon(icon, color: iconColor, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          timeago.format(createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete button and unread indicator
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.grey[600],
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Notification'),
                              content: const Text(
                                'Are you sure you want to delete this notification?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notification deleted'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting notification: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
