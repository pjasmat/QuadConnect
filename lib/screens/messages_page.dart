import 'package:flutter/material.dart';
import 'chat_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: ListView.builder(
        itemCount: 5, // placeholder
        itemBuilder: (context, index) {
          return ListTile(
            title: Text("User $index"),
            subtitle: const Text("Tap to chat"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    receiverId: "user$index",
                    receiverName: "User $index",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
