import 'package:flutter/material.dart';
import '../services/post_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController postController = TextEditingController();
  bool loading = false;
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: postController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final content = postController.text.trim();

                      if (content.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text("Please write something to post")),
                        );
                        return;
                      }

                      setState(() => loading = true);

                      try {
                        await _postService.createPost(content);
                        if (!mounted) return;
                        
                        // Clear the text field
                        postController.clear();
                        
                        // Show success message
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text("Post created successfully!"),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                        // Only pop if we can (i.e., if this page was pushed, not part of bottom nav)
                        if (navigator.canPop()) {
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (!mounted) return;
                          navigator.pop();
                        }
                      } catch (e) {
                        if (!mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text("Could not create post: $e"),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => loading = false);
                        }
                      }
                    },
                    child: const Text("Post"),
                  ),
          ],
        ),
      ),
    );
  }
}
