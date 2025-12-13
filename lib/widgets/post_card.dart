import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../screens/comments_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class InstagramPostCard extends StatelessWidget {
  final Post post;

  InstagramPostCard({super.key, required this.post});

  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService().getUser(post.uid),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const SizedBox(height: 0);

        final user = userSnapshot.data!;
        final profilePic = user["profilePicUrl"] ?? "";
        final userName = user["name"] ?? "";
        final timeAgo = timeago.format(post.createdAt);
        final currentUid = _postService.currentUid;
        final isLiked = currentUid != null && post.likes.contains(currentUid);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundImage:
                    profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
              child:
                    profilePic.isEmpty ? const Icon(Icons.person, size: 28) : null,
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(timeAgo),
            ),

            // POST IMAGE
            if (post.imageUrl != null)
              GestureDetector(
                onDoubleTap: () {
                  _postService.toggleLike(post.postId, post.likes);
                },
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 350,
                  fit: BoxFit.cover,
                ),
              ),

            // ACTION BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      _postService.toggleLike(post.postId, post.likes);
                    },
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("${post.likes.length}"),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommentsPage(postId: post.postId),
                        ),
                      );
                    },
                    child: const Icon(Icons.comment_outlined, size: 28),
                  )
                ],
              ),
            ),

            // CAPTION
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  post.content,
                  style: const TextStyle(height: 1.5, fontSize: 15),
                ),
              ),

            const SizedBox(height: 10),
          ],
        );
      },
    );
  }
}
