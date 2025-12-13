import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import 'create_post_page.dart';

class FeedPage extends StatelessWidget {
  FeedPage({super.key});

  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Feed"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostPage()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Post>>(
          stream: _postService.getPosts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading posts: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Trigger rebuild
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

            final posts = snapshot.data!;
            if (posts.isEmpty) {
              return const Center(child: Text("No posts yet"));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                try {
                  return InstagramPostCard(post: post);
                } catch (e) {
                  // Skip invalid posts
                  return const SizedBox.shrink();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
