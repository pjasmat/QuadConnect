import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/comment_service.dart';
import '../screens/comments_page.dart';
import '../screens/profile_page.dart';
import '../widgets/share_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class InstagramPostCard extends StatelessWidget {
  final Post post;

  InstagramPostCard({super.key, required this.post});

  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.white;
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService().getUser(post.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 0);

        final user = userSnapshot.data!;
        final profilePic = user["photoUrl"] ?? user["profilePicUrl"] ?? "";
        final userName = user["username"] ?? user["name"] ?? "";
        final timeAgo = timeago.format(post.createdAt);
        final currentUid = _postService.currentUid;
        final isLiked = currentUid != null && post.likes.contains(currentUid);

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // HEADER - Instagram style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: post.uid),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profilePic.isNotEmpty
                          ? (profilePic.startsWith('data:image/')
                                ? MemoryImage(
                                    base64Decode(profilePic.split(',')[1]),
                                  )
                                : NetworkImage(profilePic))
                          : null,
                      child: profilePic.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: post.uid),
                          ),
                        );
                      },
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // POST IMAGE (show first if exists) - Instagram style (square aspect ratio)
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              GestureDetector(
                onDoubleTap: () {
                  _postService.toggleLike(post.postId, post.likes);
                },
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    memCacheWidth: 400, // Optimize memory usage
                    memCacheHeight: 400,
                  ),
                ),
              ),

            // POST VIDEO (show if exists and no image) - Instagram style
            if (post.videoUrl != null &&
                post.videoUrl!.isNotEmpty &&
                (post.imageUrl == null || post.imageUrl!.isEmpty))
              GestureDetector(
                onDoubleTap: () {
                  _postService.toggleLike(post.postId, post.likes);
                },
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Video thumbnail or placeholder
                        const Icon(
                          Icons.play_circle_filled,
                          size: 64,
                          color: Colors.white,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // POST CONTENT WITH BACKGROUND (for text-only posts with background)
            if (post.backgroundColor != null &&
                post.backgroundColor!.isNotEmpty &&
                (post.imageUrl == null || post.imageUrl!.isEmpty) &&
                (post.videoUrl == null || post.videoUrl!.isEmpty))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _parseColor(post.backgroundColor!),
                ),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 18,
                    color: _getTextColorForBackground(
                      _parseColor(post.backgroundColor!),
                    ),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

            // POST CONTENT (for plain text posts without images/videos/background)
            if (post.content.isNotEmpty &&
                (post.imageUrl == null || post.imageUrl!.isEmpty) &&
                (post.videoUrl == null || post.videoUrl!.isEmpty) &&
                (post.backgroundColor == null ||
                    post.backgroundColor!.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  post.content,
                  style: const TextStyle(fontSize: 15),
                ),
              ),

            // ACTION BAR - Horizontal layout at bottom left
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.black,
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _postService.toggleLike(post.postId, post.likes);
                    },
                  ),
                  const SizedBox(width: 4),
                  StreamBuilder<int>(
                    stream: _commentService
                        .getComments(post.postId)
                        .map((comments) => comments.length),
                    builder: (context, snapshot) {
                      return IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommentsPage(postId: post.postId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ShareBottomSheet(
                          post: post,
                          userName: userName,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // LIKES COUNT - Instagram style
            if (post.likes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  '${post.likes.length} ${post.likes.length == 1 ? 'like' : 'likes'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

            // CAPTION - Instagram style (username + caption)
            if (post.content.isNotEmpty &&
                (post.imageUrl != null && post.imageUrl!.isNotEmpty ||
                    post.videoUrl != null && post.videoUrl!.isNotEmpty ||
                    post.backgroundColor != null && post.backgroundColor!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '$userName ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: post.content),
                    ],
                  ),
                ),
              ),

            // VIEW ALL COMMENTS - Instagram style
            StreamBuilder<int>(
              stream: _commentService
                  .getComments(post.postId)
                  .map((comments) => comments.length),
              builder: (context, snapshot) {
                final commentCount = snapshot.data ?? 0;
                if (commentCount > 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentsPage(postId: post.postId),
                          ),
                        );
                      },
                      child: Text(
                        'View all $commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // TIME AGO - Instagram style
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                timeAgo,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
        );
      },
    );
  }
}
