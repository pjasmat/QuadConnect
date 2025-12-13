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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
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
          final isLiked = currentUid != null && post.likes.contains(currentUid);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - Larger and more prominent
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Post Image - Larger and more prominent
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 500,
                    maxHeight: 700,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 1200,
                    placeholder: (context, url) => Container(
                      height: 500,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 500,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 80),
                      ),
                    ),
                  ),
                ),

              // Caption - Larger text (without username)
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Text(
                    post.content,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      height: 1.5,
                    ),
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
                        color: isLiked ? Colors.red : theme.iconTheme.color,
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        _postService.toggleLike(post.postId, post.likes);
                        setState(() {}); // Refresh to show updated like status
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        size: 28,
                        color: theme.iconTheme.color,
                      ),
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
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 28,
                        color: theme.iconTheme.color,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
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
                  ],
                ),
              ),

              // LIKES COUNT - Larger
              if (post.likes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    '${post.likes.length} ${post.likes.length == 1 ? 'like' : 'likes'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),

              // Divider before comments
              Divider(
                height: 32,
                thickness: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[300],
              ),
              
              // Comments Section - Keep small
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              
              _buildCommentsSection(post.postId),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentsSection(String postId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return StreamBuilder<List<Comment>>(
      stream: CommentService().getComments(postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommentsPage(postId: postId),
                  ),
                );
              },
              child: Text(
                'No comments yet. Tap to add one.',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        // Show first 5 comments, then "View all X comments" if there are more
        final displayComments = comments.take(5).toList();
        final hasMoreComments = comments.length > 5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display comments
            ...displayComments.map((comment) {
              return FutureBuilder<Map<String, dynamic>?>(
                future: UserService().getUser(comment.uid),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final user = userSnapshot.data!;
                  final userName = user["username"] ?? user["name"] ?? "User";
                  final commentTimeAgo = timeago.format(comment.createdAt);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$userName ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: comment.text),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                commentTimeAgo,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),

            // View all comments link
            if (hasMoreComments)
              Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentsPage(postId: postId),
                    ),
                  );
                },
                child: Text(
                  'View all ${comments.length} ${comments.length == 1 ? 'comment' : 'comments'}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
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
