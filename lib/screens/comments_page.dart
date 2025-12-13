import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import '../services/user_service.dart';
import '../models/comment_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsPage extends StatefulWidget {
  final String postId;
  const CommentsPage({super.key, required this.postId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: CommentService().getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading comments: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Trigger rebuild
                            setState(() {});
                          },
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
                  return const Center(
                    child: Text(
                      "No comments yet.\nBe the first to comment!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: UserService().getUser(comment.uid),
                      builder: (context, userSnapshot) {
                        final userName = userSnapshot.hasData && userSnapshot.data != null
                            ? (userSnapshot.data!["name"] ?? "Unknown User")
                            : "Loading...";
                        final profilePicUrl = userSnapshot.hasData && userSnapshot.data != null
                            ? (userSnapshot.data!["profilePicUrl"] ?? "")
                            : "";
                        final timeAgo = timeago.format(comment.createdAt);

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundImage: profilePicUrl.isNotEmpty
                                ? NetworkImage(profilePicUrl)
                                : null,
                            child: profilePicUrl.isEmpty
                                ? const Icon(Icons.person, size: 24)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              comment.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          
          // Input bar
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) return;

                    await CommentService()
                        .addComment(widget.postId, commentController.text.trim());

                    commentController.clear();
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
