import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class MessageService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // SEND MESSAGE
  Future<void> sendMessage(String receiverId, String text) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) return;
    final messageId = _db.collection("messages").doc().id;

    ChatMessage msg = ChatMessage(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
    );

    await _db.collection("messages").doc(messageId).set(msg.toMap());
  }

  // GET CHAT THREAD
  Stream<List<ChatMessage>> getMessages(String userId) {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) {
      return const Stream.empty();
    }

    // Firestore doesn't allow multiple whereIn filters, so we need to use two separate queries
    // Remove orderBy to avoid composite index requirement - we'll sort client-side
    // Query 1: Messages where current user is sender and userId is receiver
    final stream1 = _db
        .collection("messages")
        .where("senderId", isEqualTo: currentId)
        .where("receiverId", isEqualTo: userId)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            try {
              final data = doc.data();
              data["messageId"] = doc.id;
              return ChatMessage.fromMap(data);
            } catch (e) {
              print("Error parsing message ${doc.id}: $e");
              return null;
            }
          }).whereType<ChatMessage>().toList();
        });

    // Query 2: Messages where userId is sender and current user is receiver
    final stream2 = _db
        .collection("messages")
        .where("senderId", isEqualTo: userId)
        .where("receiverId", isEqualTo: currentId)
        .snapshots()
        .map((snap) {
          return snap.docs.map((doc) {
            try {
              final data = doc.data();
              data["messageId"] = doc.id;
              return ChatMessage.fromMap(data);
            } catch (e) {
              print("Error parsing message ${doc.id}: $e");
              return null;
            }
          }).whereType<ChatMessage>().toList();
        });

    // Combine both streams and merge the results in real-time
    return Stream.multi((controller) {
      List<ChatMessage> messages1 = [];
      List<ChatMessage> messages2 = [];

      void emitCombined() {
        // Combine and remove duplicates
        final allMessages = <String, ChatMessage>{};
        for (var msg in messages1) {
          allMessages[msg.messageId] = msg;
        }
        for (var msg in messages2) {
          allMessages[msg.messageId] = msg;
        }
        
        // Sort by createdAt descending (newest first)
        final sortedMessages = allMessages.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        controller.add(sortedMessages);
      }

      final sub1 = stream1.listen(
        (messages) {
          messages1 = messages;
          emitCombined();
        },
        onError: (error) {
          print("Error in stream1: $error");
          // Don't add error to controller, just log it and continue with empty list
          messages1 = [];
          emitCombined();
        },
      );

      final sub2 = stream2.listen(
        (messages) {
          messages2 = messages;
          emitCombined();
        },
        onError: (error) {
          print("Error in stream2: $error");
          // Don't add error to controller, just log it and continue with empty list
          messages2 = [];
          emitCombined();
        },
      );

      controller.onCancel = () {
        sub1.cancel();
        sub2.cancel();
      };
    });
  }
}
