import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/comment_model.dart';
import '../screens/profile_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsPage extends StatefulWidget {
  final String postId;
  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToCommentId;
  String? _editingCommentId;
  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, TextEditingController> _editControllers = {};
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      setState(() {}); // Update UI when text changes
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    for (var controller in _editControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _commentService.addComment(
        widget.postId,
        _commentController.text.trim(),
        parentCommentId: _replyingToCommentId,
      );
      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUserName = null;
      });
      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editComment(String commentId, String newText) async {
    try {
      await _commentService.editComment(commentId, newText);
      setState(() => _editingCommentId = null);
      _editControllers[commentId]?.dispose();
      _editControllers.remove(commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error editing comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
        await _commentService.deleteComment(commentId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting comment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildCommentItem(Comment comment, {bool isReply = false}) {
    final currentUid = _authService.currentUser?.uid;
    final isOwner = currentUid == comment.uid;
    final isLiked = currentUid != null && comment.likes.contains(currentUid);

    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService().getUser(comment.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        final user = userSnapshot.data!;
        final userName = user["username"] ?? user["name"] ?? "Unknown User";
        final profilePicUrl = user["photoUrl"] ?? user["profilePicUrl"] ?? "";
        final timeAgo = timeago.format(comment.createdAt);
        final isEdited = comment.editedAt != null;

        return Container(
          margin: EdgeInsets.only(left: isReply ? 48.0 : 0, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(userId: comment.uid),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: isReply ? 14 : 18,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profilePicUrl.isNotEmpty
                          ? (profilePicUrl.startsWith('data:image/')
                                ? MemoryImage(
                                    base64Decode(profilePicUrl.split(',')[1]),
                                  )
                                : NetworkImage(profilePicUrl))
                          : null,
                      child: profilePicUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: isReply ? 18 : 22,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Comment Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comment Bubble
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: _editingCommentId == comment.commentId
                              ? _buildEditInput(comment)
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Username and time
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ProfilePage(
                                                  userId: comment.uid,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            userName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: theme.textTheme.bodyLarge?.color,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        if (isEdited) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '• edited',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 4),
                        // Action buttons
                        Row(
                          children: [
                            // Like button
                            InkWell(
                              onTap: () {
                                _commentService.toggleLike(
                                  comment.commentId,
                                  comment.likes,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 16,
                                      color: isLiked ? Colors.red : Colors.grey,
                                    ),
                                    if (comment.likes.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '${comment.likes.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            // Reply button
                            if (!isReply)
                              InkWell(
                                onTap: () async {
                                  final user = await UserService().getUser(
                                    comment.uid,
                                  );
                                  final userName =
                                      user?["username"] ??
                                      user?["name"] ??
                                      "User";
                                  setState(() {
                                    _replyingToCommentId = comment.commentId;
                                    _replyingToUserName = userName;
                                    _commentController.clear();
                                  });
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(FocusNode());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    'Reply',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            // Edit button (only for owner)
                            if (isOwner && !isReply)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _editingCommentId = comment.commentId;
                                    _editControllers[comment.commentId] =
                                        TextEditingController(
                                          text: comment.text,
                                        );
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            // Delete button (only for owner)
                            if (isOwner)
                              InkWell(
                                onTap: () => _deleteComment(comment.commentId),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Replies
              if (!isReply)
                StreamBuilder<List<Comment>>(
                  stream: _commentService.getReplies(comment.commentId),
                  builder: (context, repliesSnapshot) {
                    if (!repliesSnapshot.hasData ||
                        repliesSnapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final replies = repliesSnapshot.data!;
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        ...replies.map(
                          (reply) => _buildCommentItem(reply, isReply: true),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditInput(Comment comment) {
    if (!_editControllers.containsKey(comment.commentId)) {
      _editControllers[comment.commentId] = TextEditingController(
        text: comment.text,
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _editControllers[comment.commentId],
            autofocus: true,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Edit comment...',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final newText =
                _editControllers[comment.commentId]?.text.trim() ?? '';
            if (newText.isNotEmpty) {
              _editComment(comment.commentId, newText);
            } else {
              setState(() => _editingCommentId = null);
            }
          },
          child: Text(
            'Save',
            style: TextStyle(fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() => _editingCommentId = null);
          },
          child: Text(
            'Cancel',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _authService.currentUser?.uid;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          "Comments",
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _commentService.getComments(widget.postId),
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
                        Text(
                          'Error loading comments: ${snapshot.error}',
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No comments yet.\nBe the first to comment!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return _buildCommentItem(comments[index]);
                    },
                  ),
                );
              },
            ),
          ),

          // Reply indicator
          if (_replyingToCommentId != null && _replyingToUserName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              child: Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to $_replyingToUserName',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.iconTheme.color,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _replyingToCommentId = null;
                        _replyingToUserName = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Input bar
          if (currentUid != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? "Add a reply..."
                              : "Add a comment...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _addComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: _commentController.text.trim().isNotEmpty
                          ? Colors.blue
                          : Colors.grey[300],
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _commentController.text.trim().isNotEmpty
                            ? _addComment
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
