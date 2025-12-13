import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import '../services/user_service.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Messages")),
        body: const Center(child: Text("Please log in to view messages")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: UserService().getAllUsers(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading users: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No other users found"),
                  SizedBox(height: 8),
                  Text(
                    "Make sure other users have signed up\nand their accounts exist in Firestore",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userName = user["name"] ?? "Unknown User";
              final userEmail = user["email"] ?? "";
              final profilePicUrl = user["profilePicUrl"] ?? "";
              
              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: profilePicUrl.isNotEmpty 
                      ? NetworkImage(profilePicUrl) 
                      : null,
                  child: profilePicUrl.isEmpty 
                      ? const Icon(Icons.person, size: 28) 
                      : null,
                ),
                title: Text(userName),
                subtitle: Text(userEmail),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        receiverId: user["uid"],
                        receiverName: userName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
