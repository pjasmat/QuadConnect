import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/post_service.dart';
import '../utils/error_messages.dart';

enum PostType { text, image, video }

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService();

  PostType _selectedType = PostType.text;
  File? _selectedImage;
  File? _selectedVideo;
  bool _isLoading = false;
  Color _selectedBackgroundColor = Colors.white;
  bool _useCustomBackground = false;

  // Predefined background colors for text posts
  final List<Color> _backgroundColors = [
    Colors.white,
    Colors.blue.shade50,
    Colors.purple.shade50,
    Colors.pink.shade50,
    Colors.green.shade50,
    Colors.orange.shade50,
    Colors.teal.shade50,
    Colors.indigo.shade50,
    Colors.red.shade50,
    Colors.yellow.shade50,
    Colors.cyan.shade50,
    Colors.amber.shade50,
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedVideo = null;
          _selectedType = PostType.image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          _selectedImage = null;
          _selectedType = PostType.video;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getUserFriendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, size: 28),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, size: 28),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, size: 28),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, size: 28),
              title: const Text('Choose Video from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _autoSelectBackground() {
    // Auto-select a random background color
    final random =
        DateTime.now().millisecondsSinceEpoch % _backgroundColors.length;
    setState(() {
      _selectedBackgroundColor = _backgroundColors[random];
      _useCustomBackground = true;
    });
  }

  Future<String?> _uploadMedia(File file, String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      // Check file size (limit to 10MB for images, 50MB for videos)
      final fileSize = await file.length();
      final maxSize = type == 'image' ? 10 * 1024 * 1024 : 50 * 1024 * 1024;
      if (fileSize > maxSize) {
        throw Exception(
          type == 'image'
              ? 'Image size exceeds 10MB limit'
              : 'Video size exceeds 50MB limit',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = type == 'image' ? 'jpg' : 'mp4';
      final fileName = "${type}s/${user.uid}_$timestamp.$extension";

      try {
        final ref = FirebaseStorage.instance.ref(fileName);
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: type == 'image' ? 'image/jpeg' : 'video/mp4',
          ),
        );

        // Wait for upload to complete
        final snapshot = await uploadTask;

        if (snapshot.state == TaskState.success) {
          final downloadUrl = await ref.getDownloadURL();
          return downloadUrl;
        } else {
          throw Exception('Upload failed: ${snapshot.state}');
        }
      } catch (storageError) {
        // Check if it's a storage-related error (billing, not enabled, etc.)
        final errorString = storageError.toString().toLowerCase();
        if (errorString.contains('billing') ||
            errorString.contains('upgrade') ||
            errorString.contains('object-not-found') ||
            errorString.contains('permission-denied') ||
            errorString.contains('storage/object-not-found')) {
          // For images only, we can use a fallback to base64 in Firestore
          if (type == 'image') {
            // Check if image is small enough for Firestore (1MB limit, base64 adds ~33% overhead)
            if (fileSize > 750000) {
              throw Exception(
                'Image too large for fallback method. Please use a smaller image (max 750KB) or enable Firebase Storage.',
              );
            }

            // Read image as bytes and convert to base64
            final bytes = await file.readAsBytes();
            final base64Image = base64Encode(bytes);
            // Return as data URL (will be stored in post document)
            return 'data:image/jpeg;base64,$base64Image';
          } else {
            // For videos, we can't use base64 fallback (too large)
            throw Exception(
              'Firebase Storage is not available. Please enable Firebase Storage in the Firebase Console to upload videos.',
            );
          }
        } else {
          // Re-throw other errors
          rethrow;
        }
      }
    } catch (e) {
      // Re-throw with more context
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission') ||
          errorString.contains('permission-denied')) {
        throw Exception(
          'Storage permission denied. Please check Firebase Storage rules or enable Storage in Firebase Console.',
        );
      } else if (errorString.contains('network') ||
          errorString.contains('network')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else {
        throw Exception('Failed to upload $type: ${e.toString()}');
      }
    }
  }

  Future<void> _createPost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty && _selectedImage == null && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add some content, image, or video to your post',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      String? videoUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        try {
          imageUrl = await _uploadMedia(_selectedImage!, 'image');
          if (imageUrl == null || imageUrl.isEmpty) {
            throw Exception('Image upload returned empty URL');
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorMessages.getUserFriendlyError(e)),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // Upload video if selected
      if (_selectedVideo != null) {
        try {
          videoUrl = await _uploadMedia(_selectedVideo!, 'video');
          if (videoUrl == null || videoUrl.isEmpty) {
            throw Exception('Video upload returned empty URL');
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorMessages.getUserFriendlyError(e)),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      // Convert background color to hex string if custom background is used
      String? backgroundColorHex;
      if (_useCustomBackground && _selectedType == PostType.text) {
        backgroundColorHex =
            '#${_selectedBackgroundColor.value.toRadixString(16).substring(2)}';
      }

      // Create post with media URL and background
      await _postService.createPost(
        content,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        backgroundColor: backgroundColorHex,
      );

      if (!mounted) return;

      // Clear form
      _contentController.clear();
      setState(() {
        _selectedImage = null;
        _selectedVideo = null;
        _selectedType = PostType.text;
        _selectedBackgroundColor = Colors.white;
        _useCustomBackground = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (Navigator.of(context).canPop()) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorMessages.getUserFriendlyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              _createPost();
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Post Type Selector
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTypeButton(
                    icon: Icons.text_fields,
                    label: 'Text',
                    type: PostType.text,
                  ),
                  _buildTypeButton(
                    icon: Icons.image,
                    label: 'Image',
                    type: PostType.image,
                  ),
                  _buildTypeButton(
                    icon: Icons.videocam,
                    label: 'Video',
                    type: PostType.video,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content Area
            Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: BoxDecoration(
                color: _selectedType == PostType.text && _useCustomBackground
                    ? _selectedBackgroundColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Input
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 8,
                    style: TextStyle(
                      fontSize: 18,
                      color:
                          _useCustomBackground && _selectedType == PostType.text
                          ? _getTextColorForBackground(_selectedBackgroundColor)
                          : Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  // Media Preview
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  if (_contentController.text.isEmpty) {
                                    _selectedType = PostType.text;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (_selectedVideo != null) ...[
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedVideo = null;
                                  if (_contentController.text.isEmpty) {
                                    _selectedType = PostType.text;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Background Options (for text posts)
            if (_selectedType == PostType.text) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Background',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('Auto Select'),
                          onPressed: _autoSelectBackground,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        // Custom color picker
                        GestureDetector(
                          onTap: () async {
                            final color = await showDialog<Color>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Select Background Color'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _backgroundColors.map((color) {
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: color,
                                        ),
                                        title: Text(_getColorName(color)),
                                        onTap: () =>
                                            Navigator.pop(context, color),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                            if (color != null) {
                              setState(() {
                                _selectedBackgroundColor = color;
                                _useCustomBackground = true;
                              });
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _useCustomBackground
                                  ? _selectedBackgroundColor
                                  : Colors.white,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _useCustomBackground
                                ? null
                                : const Icon(Icons.color_lens),
                          ),
                        ),
                        // Predefined colors
                        ..._backgroundColors.map((color) {
                          final isSelected =
                              _useCustomBackground &&
                              _selectedBackgroundColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBackgroundColor = color;
                                _useCustomBackground = true;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[300]!,
                                  width: isSelected ? 3 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }),
                        // Remove background
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _useCustomBackground = false;
                              _selectedBackgroundColor = Colors.white;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.clear),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Media Selection Buttons
            if (_selectedImage == null && _selectedVideo == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Media'),
                        onPressed: _showMediaPicker,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required IconData icon,
    required String label,
    required PostType type,
  }) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          if (type != PostType.text) {
            _useCustomBackground = false;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculate luminance to determine if text should be dark or light
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  String _getColorName(Color color) {
    if (color == Colors.white) return 'White';
    if (color == Colors.blue.shade50) return 'Light Blue';
    if (color == Colors.purple.shade50) return 'Light Purple';
    if (color == Colors.pink.shade50) return 'Light Pink';
    if (color == Colors.green.shade50) return 'Light Green';
    if (color == Colors.orange.shade50) return 'Light Orange';
    if (color == Colors.teal.shade50) return 'Light Teal';
    if (color == Colors.indigo.shade50) return 'Light Indigo';
    if (color == Colors.red.shade50) return 'Light Red';
    if (color == Colors.yellow.shade50) return 'Light Yellow';
    if (color == Colors.cyan.shade50) return 'Light Cyan';
    if (color == Colors.amber.shade50) return 'Light Amber';
    return 'Custom';
  }
}
