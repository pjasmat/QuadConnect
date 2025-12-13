import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';
import 'notification_helper.dart';

class ShareService {
  // Share a post with improved formatting
  Future<void> sharePost(Post post, {String? userName}) async {
    try {
      final content = post.content;
      final imageUrl = post.imageUrl;
      final videoUrl = post.videoUrl;

      // Create formatted share text
      String shareText = '📱 QuadConnect\n\n';
      
      if (userName != null) {
        shareText += 'Posted by @$userName\n\n';
      }
      
      if (content.isNotEmpty) {
        shareText += '$content\n\n';
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        shareText += '🖼️ Image included\n';
      }
      
      if (videoUrl != null && videoUrl.isNotEmpty) {
        shareText += '🎥 Video included\n';
      }

      shareText += '\nDownload QuadConnect to see more!';

      if (kDebugMode) {
        print('Sharing post: $shareText');
      }

      await Share.share(shareText, subject: 'Post from QuadConnect');
      
      if (kDebugMode) {
        print('Share completed');
      }

      // Notify post owner about share
      try {
        final notificationHelper = NotificationHelper();
        await notificationHelper.notifyPostShared(post.postId, post.uid);
      } catch (e) {
        if (kDebugMode) {
          print('Error sending share notification: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing post: $e');
      }
      rethrow;
    }
  }

  // Copy post link to clipboard
  Future<void> copyPostLink(Post post) async {
    try {
      // In a real app, this would be a deep link
      final link = 'quadconnect://post/${post.postId}';
      await Clipboard.setData(ClipboardData(text: link));
    } catch (e) {
      if (kDebugMode) {
        print('Error copying post link: $e');
      }
      rethrow;
    }
  }

  // Copy post content to clipboard
  Future<void> copyPostContent(Post post, {String? userName}) async {
    try {
      String content = '';
      if (userName != null) {
        content = 'Posted by @$userName\n\n';
      }
      content += post.content;
      
      await Clipboard.setData(ClipboardData(text: content));
    } catch (e) {
      if (kDebugMode) {
        print('Error copying post content: $e');
      }
      rethrow;
    }
  }

  // Share an event with improved formatting
  Future<void> shareEvent(EventModel event) async {
    try {
      final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
      final formattedDate = dateFormat.format(event.date);

      final shareText = '''
📅 QuadConnect Event

🎯 ${event.title}

${event.description}

📍 Location: ${event.location}
📆 Date: $formattedDate
${event.capacity != null ? '👥 Capacity: ${event.attendees.length}/${event.capacity}' : '👥 ${event.attendees.length} attending'}

Download QuadConnect to RSVP and see more events!
''';

      if (kDebugMode) {
        print('Sharing event: ${event.title}');
      }

      await Share.share(shareText, subject: 'Event: ${event.title}');
      
      if (kDebugMode) {
        print('Share completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing event: $e');
      }
      rethrow;
    }
  }

  // Copy event link to clipboard
  Future<void> copyEventLink(EventModel event) async {
    try {
      final link = 'quadconnect://event/${event.eventId}';
      await Clipboard.setData(ClipboardData(text: link));
    } catch (e) {
      if (kDebugMode) {
        print('Error copying event link: $e');
      }
      rethrow;
    }
  }

  // Share user profile with improved formatting
  Future<void> shareProfile(String userId, String userName, {String? bio}) async {
    try {
      String shareText = '👤 Check out @$userName on QuadConnect!\n\n';
      
      if (bio != null && bio.isNotEmpty) {
        shareText += '$bio\n\n';
      }
      
      shareText += 'Download QuadConnect to connect!';
      
      if (kDebugMode) {
        print('Sharing profile: $userName');
      }

      await Share.share(shareText, subject: '$userName on QuadConnect');
      
      if (kDebugMode) {
        print('Share completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing profile: $e');
      }
      rethrow;
    }
  }

  // Copy profile link to clipboard
  Future<void> copyProfileLink(String userId, String userName) async {
    try {
      final link = 'quadconnect://profile/$userId';
      await Clipboard.setData(ClipboardData(text: link));
    } catch (e) {
      if (kDebugMode) {
        print('Error copying profile link: $e');
      }
      rethrow;
    }
  }
}
