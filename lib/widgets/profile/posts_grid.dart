import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../widgets/media/image_viewer.dart';

class PostsGrid extends StatelessWidget {
  final List<Post> posts;

  const PostsGrid({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageViewer(imageUrl: post.imageUrl!),
              ),
            );
          },
          child: Hero(
            tag: post.imageUrl!,
            child: Image.network(
              post.imageUrl!,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
