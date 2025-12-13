import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final websiteController = TextEditingController();
  final linkedinController = TextEditingController();
  final instagramController = TextEditingController();
  final twitterController = TextEditingController();
  final githubController = TextEditingController();
  File? selectedImage;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    usernameController.dispose();
    bioController.dispose();
    websiteController.dispose();
    linkedinController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    githubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser!.uid;

    return StreamBuilder<AppUser>(
      stream: UserService().getUserModelStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        // Initialize controllers only once
        if (!_isInitialized) {
          usernameController.text = user.username;
          bioController.text = user.bio;
          websiteController.text = user.website ?? "";
          linkedinController.text = user.linkedin ?? "";
          instagramController.text = user.instagram ?? "";
          twitterController.text = user.twitter ?? "";
          githubController.text = user.github ?? "";
          _isInitialized = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text("Edit Profile")),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: selectedImage != null
                                  ? FileImage(selectedImage!)
                                  : (user.photoUrl != null
                                            ? (user.photoUrl!.startsWith(
                                                    'data:image/',
                                                  )
                                                  ? MemoryImage(
                                                      base64Decode(
                                                        user.photoUrl!.split(
                                                          ',',
                                                        )[1],
                                                      ),
                                                    )
                                                  : NetworkImage(
                                                      user.photoUrl!,
                                                    ))
                                            : null)
                                        as ImageProvider?,
                              child:
                                  user.photoUrl == null && selectedImage == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to change profile picture',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: "Username",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: bioController,
                        decoration: const InputDecoration(
                          labelText: "Bio",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        "Social Links",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: websiteController,
                        decoration: const InputDecoration(
                          labelText: "Website",
                          hintText: "https://example.com",
                          prefixIcon: Icon(Icons.language),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: linkedinController,
                        decoration: const InputDecoration(
                          labelText: "LinkedIn",
                          hintText: "linkedin.com/in/username",
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: instagramController,
                        decoration: const InputDecoration(
                          labelText: "Instagram",
                          hintText: "instagram.com/username",
                          prefixIcon: Icon(Icons.camera_alt),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: twitterController,
                        decoration: const InputDecoration(
                          labelText: "Twitter",
                          hintText: "twitter.com/username",
                          prefixIcon: Icon(Icons.chat_bubble_outline),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: githubController,
                        decoration: const InputDecoration(
                          labelText: "GitHub",
                          hintText: "github.com/username",
                          prefixIcon: Icon(Icons.code),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.url,
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => saveProfile(user),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Save Changes"),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<void> pickImage() async {
    // Show dialog to choose between camera and gallery
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85, // Compress image
      );

      if (picked != null) {
        setState(() => selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> saveProfile(AppUser user) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = user.photoUrl;

      // Upload image if selected
      if (selectedImage != null) {
        try {
          // Verify user is authenticated
          final currentUser = AuthService().currentUser;
          if (currentUser == null) {
            throw Exception('User not authenticated');
          }

          // Verify file exists
          if (!await selectedImage!.exists()) {
            throw Exception('Selected image file does not exist');
          }

          // Get file size to ensure it's valid
          final fileLength = await selectedImage!.length();
          if (fileLength == 0) {
            throw Exception('Selected image file is empty');
          }

          // Try Firebase Storage first
          bool storageSuccess = false;
          try {
            // Create a unique filename with timestamp to avoid conflicts
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = "profile_images/${user.uid}_$timestamp.jpg";

            // Get Firebase Storage instance
            final storage = FirebaseStorage.instance;

            // Try creating reference
            final ref = storage.ref(fileName);

            // Upload file with metadata
            final uploadTask = ref.putFile(
              selectedImage!,
              SettableMetadata(
                contentType: 'image/jpeg',
                customMetadata: {'uid': user.uid},
              ),
            );

            // Wait for upload to complete and get snapshot
            final snapshot = await uploadTask;

            // Verify upload was successful
            if (snapshot.state == TaskState.success) {
              // Get download URL
              photoUrl = await ref.getDownloadURL();
              storageSuccess = true;
            }
          } catch (storageError) {
            // If Storage fails (billing/not enabled), fall back to base64
            if (storageError.toString().contains('billing') ||
                storageError.toString().contains('upgrade') ||
                storageError.toString().contains('object-not-found')) {
              // Fallback: Store as base64 in Firestore
              final bytes = await selectedImage!.readAsBytes();

              // Check size limit (Firestore has 1MB limit, base64 adds ~33% overhead)
              // So we limit to ~750KB original size
              if (bytes.length > 750000) {
                throw Exception(
                  'Image too large. Please use a smaller image (max 750KB)',
                );
              }

              // Convert to base64
              final base64Image = base64Encode(bytes);
              // Store as data URL
              photoUrl = 'data:image/jpeg;base64,$base64Image';
              storageSuccess = true;
            } else {
              // Re-throw if it's a different error
              throw storageError;
            }
          }

          if (!storageSuccess) {
            throw Exception('Failed to upload image');
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isLoading = false);

            // More detailed error message
            String errorMessage = 'Error uploading image: $e';
            if (e.toString().contains('object-not-found') ||
                e.toString().contains('billing') ||
                e.toString().contains('upgrade')) {
              errorMessage =
                  'Storage not available. Using alternative method. If this fails, please enable Firebase Storage in the console.';
            } else if (e.toString().contains('permission-denied')) {
              errorMessage =
                  'Permission denied: Check Firebase Storage security rules';
            } else if (e.toString().contains('unauthorized')) {
              errorMessage = 'Unauthorized: Please make sure you are logged in';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            return;
          }
        }
      }

      // Update user profile
      await UserService().updateProfile(user.uid, {
        "username": usernameController.text.trim(),
        "bio": bioController.text.trim(),
        "photoUrl": photoUrl,
        "website": websiteController.text.trim().isEmpty
            ? null
            : websiteController.text.trim(),
        "linkedin": linkedinController.text.trim().isEmpty
            ? null
            : linkedinController.text.trim(),
        "instagram": instagramController.text.trim().isEmpty
            ? null
            : instagramController.text.trim(),
        "twitter": twitterController.text.trim().isEmpty
            ? null
            : twitterController.text.trim(),
        "github": githubController.text.trim().isEmpty
            ? null
            : githubController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
