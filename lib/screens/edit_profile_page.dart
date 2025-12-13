import 'dart:io';
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
  File? selectedImage;

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

        usernameController.text = user.username;
        bioController.text = user.bio;

        return Scaffold(
          appBar: AppBar(title: const Text("Edit Profile")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: selectedImage != null
                        ? FileImage(selectedImage!)
                        : (user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null) as ImageProvider?,
                    child: user.photoUrl == null && selectedImage == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: "Bio"),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () => saveProfile(user),
                  child: const Text("Save Changes"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> saveProfile(AppUser user) async {
    final navigator = Navigator.of(context);
    String? photoUrl = user.photoUrl;

    if (selectedImage != null) {
      final ref = FirebaseStorage.instance.ref("profile_images/${user.uid}.jpg");
      await ref.putFile(selectedImage!);
      photoUrl = await ref.getDownloadURL();
    }

    await UserService().updateProfile(user.uid, {
      "username": usernameController.text.trim(),
      "bio": bioController.text.trim(),
      "photoUrl": photoUrl,
    });

    if (mounted) {
      navigator.pop();
    }
  }
}
