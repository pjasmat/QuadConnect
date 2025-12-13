import 'package:flutter/material.dart';
import '../services/share_service.dart';
import '../models/post_model.dart';
import '../models/event_model.dart';

class ShareBottomSheet extends StatelessWidget {
  final Post? post;
  final EventModel? event;
  final String? userName;
  final String? userId;
  final String? userBio;

  ShareBottomSheet({
    super.key,
    this.post,
    this.event,
    this.userName,
    this.userId,
    this.userBio,
  }) : assert(post != null || event != null || userId != null,
            'Must provide post, event, or userId');

  final ShareService _shareService = ShareService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              post != null
                  ? 'Share Post'
                  : event != null
                      ? 'Share Event'
                      : 'Share Profile',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Share options
          if (post != null) _buildPostShareOptions(context),
          if (event != null) _buildEventShareOptions(context),
          if (userId != null) _buildProfileShareOptions(context),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPostShareOptions(BuildContext context) {
    return Column(
      children: [
        _buildShareOption(
          context,
          icon: Icons.share,
          title: 'Share via...',
          subtitle: 'Share to other apps',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.sharePost(post!, userName: userName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post shared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sharing: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        _buildShareOption(
          context,
          icon: Icons.link,
          title: 'Copy Link',
          subtitle: 'Copy post link to clipboard',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.copyPostLink(post!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error copying link: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        _buildShareOption(
          context,
          icon: Icons.content_copy,
          title: 'Copy Text',
          subtitle: 'Copy post content to clipboard',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.copyPostContent(post!, userName: userName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Content copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error copying content: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildEventShareOptions(BuildContext context) {
    return Column(
      children: [
        _buildShareOption(
          context,
          icon: Icons.share,
          title: 'Share via...',
          subtitle: 'Share to other apps',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.shareEvent(event!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event shared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sharing: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        _buildShareOption(
          context,
          icon: Icons.link,
          title: 'Copy Link',
          subtitle: 'Copy event link to clipboard',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.copyEventLink(event!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error copying link: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildProfileShareOptions(BuildContext context) {
    return Column(
      children: [
        _buildShareOption(
          context,
          icon: Icons.share,
          title: 'Share via...',
          subtitle: 'Share to other apps',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.shareProfile(userId!, userName ?? 'User', bio: userBio);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile shared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sharing: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        _buildShareOption(
          context,
          icon: Icons.link,
          title: 'Copy Link',
          subtitle: 'Copy profile link to clipboard',
          onTap: () async {
            Navigator.pop(context);
            try {
              await _shareService.copyProfileLink(userId!, userName ?? 'User');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error copying link: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

