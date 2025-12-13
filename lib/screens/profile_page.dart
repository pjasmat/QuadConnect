import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/profile/posts_grid.dart';
import '../models/post_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
      ),
      body: StreamBuilder<List<Post>>(
        stream: PostService().getPostsByUser(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(radius: 45, child: Icon(Icons.person, size: 50)),
                const SizedBox(height: 10),
                const Text("My Posts", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 20),

                PostsGrid(posts: posts),
              ],
            ),
          );
        },
      ),
    );
  }
}
