import 'package:flutter/material.dart';
import '../services/comment_service.dart';
import '../models/comment_model.dart';

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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;

                if (comments.isEmpty) {
                  return const Center(child: Text("No comments yet"));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return ListTile(
                      title: Text(c.text),
                      subtitle: Text(
                        "Posted at ${c.createdAt.toString().substring(0, 16)}",
                      ),
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
