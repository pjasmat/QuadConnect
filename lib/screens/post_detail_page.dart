import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';
import '../screens/comments_page.dart';
import '../widgets/share_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailPage extends StatefulWidget {
  final Post post;
  final List<Post> allPosts;
  final int initialIndex;

  const PostDetailPage({
    super.key,
    required this.post,
    required this.allPosts,
    this.initialIndex = 0,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    final currentPost = widget.allPosts[_currentIndex];
    final isOwner = currentUid != null && currentPost.uid == currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          // Settings icon - only show if post belongs to current user
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Get the current post from the page
                final post = widget.allPosts[_currentIndex];
                _showSettingsMenu(context, post);
              },
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.allPosts.length,
        itemBuilder: (context, index) {
          final initialPost = widget.allPosts[index];
          // Use StreamBuilder to get real-time updates for the current post
          return StreamBuilder<List<Post>>(
            stream: _postService.getPostsByUser(initialPost.uid),
            builder: (context, snapshot) {
              Post post = initialPost;
              if (snapshot.hasData) {
                final updatedPost = snapshot.data!.firstWhere(
                  (p) => p.postId == initialPost.postId,
                  orElse: () => initialPost,
                );
                post = updatedPost;
              }
              return _buildPostDetail(post, currentUid);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostDetail(Post post, String? currentUid) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Post content
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: FutureBuilder<Map<String, dynamic>?>(
              future: UserService().getUser(post.uid),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = userSnapshot.data!;
                final profilePic =
                    user["photoUrl"] ?? user["profilePicUrl"] ?? "";
                final userName = user["username"] ?? user["name"] ?? "";
                final timeAgo = timeago.format(post.createdAt);

                final isOwner = currentUid != null && post.uid == currentUid;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Settings Icon
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            radius: 25,
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
                                    size: 30,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(timeAgo),
                        ),
                        // Settings icon in top-right corner
                        if (isOwner)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Material(
                              color: Colors.transparent,
                              child: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () {
                                  _showSettingsMenu(context, post);
                                },
                                tooltip: 'Post options',
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Post Image
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        memCacheWidth: 800,
                        placeholder: (context, url) => Container(
                          height: 300,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 300,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),

                    // Caption
                    if (post.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          post.content,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),

        // Right side - Actions and Comments
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Like button
              _buildActionButton(
                icon: currentUid != null && post.likes.contains(currentUid)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: Colors.red,
                count: post.likes.length,
                onTap: () {
                  _postService.toggleLike(post.postId, post.likes);
                  setState(() {}); // Refresh to show updated like status
                },
              ),
              const SizedBox(height: 20),
              // Comment button
              StreamBuilder<List<Comment>>(
                stream: CommentService().getComments(post.postId),
                builder: (context, snapshot) {
                  final commentCount = snapshot.hasData
                      ? snapshot.data!.length
                      : 0;
                  return _buildActionButton(
                    icon: Icons.comment_outlined,
                    color: Colors.blue,
                    count: commentCount,
                    onTap: () {
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
              const SizedBox(height: 20),
              // Share button
              _buildActionButton(
                icon: Icons.share_outlined,
                color: Colors.grey,
                count: 0,
                onTap: () async {
                  try {
                    final user = await UserService().getUser(post.uid);
                    final userName = user?["username"] ?? user?["name"] ?? "";
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ShareBottomSheet(
                        post: post,
                        userName: userName,
                      ),
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error sharing post: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              // Comments preview
              _buildCommentsPreview(post.postId),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsPreview(String postId) {
    return StreamBuilder<List<Comment>>(
      stream: CommentService().getComments(postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show only first 2-3 comments
        final previewComments = comments.take(3).toList();

        return Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: previewComments.map((comment) {
                return FutureBuilder<Map<String, dynamic>?>(
                  future: UserService().getUser(comment.uid),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final user = userSnapshot.data!;
                    final userName = user["username"] ?? user["name"] ?? "User";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comment.text,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showSettingsMenu(BuildContext context, Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Post',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, post);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Post post) {
    final contentController = TextEditingController(text: post.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: contentController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter post content',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post content cannot be empty')),
                );
                return;
              }

              try {
                await _postService.updatePost(
                  post.postId,
                  contentController.text.trim(),
                );
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh the page
                  setState(() {});
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Deleting post...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              try {
                final postIdToDelete = post.postId;

                if (postIdToDelete.isEmpty) {
                  throw Exception('Invalid post ID');
                }

                await _postService.deletePost(postIdToDelete);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Post deleted successfully'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context); // Go back to profile
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting post: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
