import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/profile/posts_grid.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'chat_page.dart';

class ProfilePage extends StatelessWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUser?.uid;
    final uid = userId ?? currentUid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: const Center(child: Text("Please log in to view profile")),
      );
    }

    final authService = AuthService();
    final isOwnProfile = userId == null || userId == currentUid;
    
    // Get theme provider in build method where context is available
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: isOwnProfile
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  onSelected: (value) async {
                    if (value == 'darkmode') {
                      await themeProvider.toggleTheme();
                    } else if (value == 'logout') {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true && context.mounted) {
                        await authService.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (BuildContext menuContext) {
                    return [
                      PopupMenuItem<String>(
                        value: 'darkmode',
                        child: Row(
                          children: [
                            Icon(
                              isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ]
            : [],
      ),
      body: StreamBuilder<AppUser>(
        stream: UserService().getUserModelStream(uid),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data!;
          final postService = PostService();

          return StreamBuilder<List<Post>>(
            stream: postService.getPostsByUser(uid),
            builder: (context, postsSnapshot) {
              if (postsSnapshot.hasError) {
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
                      Text('Error: ${postsSnapshot.error}'),
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

              if (!postsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = postsSnapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Picture (Centered)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: user.photoUrl != null
                          ? (user.photoUrl!.startsWith('data:image/')
                                ? MemoryImage(
                                    base64Decode(user.photoUrl!.split(',')[1]),
                                  )
                                : CachedNetworkImageProvider(user.photoUrl!))
                          : null,
                      child: user.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Username/User ID (Centered)
                    Text(
                      user.username.isNotEmpty
                          ? user.username
                          : user.uid.substring(0, 8),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Bio (Centered)
                    if (user.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          user.bio,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Social Links
                    _buildSocialLinks(context, user),
                    const SizedBox(height: 20),
                    // Edit Profile or Direct Message Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: isOwnProfile
                            ? OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfilePage(),
                                    ),
                                  );
                                },
                                child: const Text('Edit Profile'),
                              )
                            : ElevatedButton.icon(
                                onPressed: () {
                                  final receiverName = user.username.isNotEmpty
                                      ? user.username
                                      : user.uid.substring(0, 8);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        receiverId: uid,
                                        receiverName: receiverName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('Direct Message'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Posts Grid
                    if (posts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      PostsGrid(
                        posts: posts,
                        onPostUpdated: () {
                          // Trigger rebuild to refresh posts
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSocialLinks(BuildContext context, AppUser user) {
    final links = <Map<String, dynamic>>[];

    if (user.website != null && user.website!.isNotEmpty) {
      links.add({
        'icon': Icons.public,
        'url': user.website!,
        'color': Colors.blue,
        'label': 'Website',
      });
    }
    if (user.linkedin != null && user.linkedin!.isNotEmpty) {
      links.add({
        'icon': Icons.business_center,
        'url': user.linkedin!,
        'color': const Color(0xFF0077B5), // LinkedIn blue
        'label': 'LinkedIn',
      });
    }
    if (user.instagram != null && user.instagram!.isNotEmpty) {
      links.add({
        'icon': Icons.photo_camera,
        'url': user.instagram!,
        'color': const Color(0xFFE4405F), // Instagram pink
        'label': 'Instagram',
      });
    }
    if (user.twitter != null && user.twitter!.isNotEmpty) {
      links.add({
        'icon': Icons.alternate_email,
        'url': user.twitter!,
        'color': const Color(0xFF1DA1F2), // Twitter blue
        'label': 'Twitter',
      });
    }
    if (user.github != null && user.github!.isNotEmpty) {
      links.add({
        'icon': Icons.code,
        'url': user.github!,
        'color': Colors.black87,
        'label': 'GitHub',
      });
    }

    if (links.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: links.map((link) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _launchURL(context, link['url'] as String),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (link['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: link['color'] as Color, width: 1.5),
                ),
                child: Icon(
                  link['icon'] as IconData,
                  color: link['color'] as Color,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    try {
      String finalUrl = url.trim();

      // Remove any trailing slashes
      if (finalUrl.endsWith('/')) {
        finalUrl = finalUrl.substring(0, finalUrl.length - 1);
      }

      // Add https:// if not present
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }

      final uri = Uri.parse(finalUrl);

      // Launch URL directly
      final launched = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open link. Please check your internet connection.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
