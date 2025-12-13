import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class MessageService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // SEND MESSAGE
  Future<void> sendMessage(
    String receiverId,
    String text, {
    String? replyToMessageId,
    String? replyToText,
    String? imageUrl,
  }) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) return;
    final messageId = _db.collection("messages").doc().id;

    ChatMessage msg = ChatMessage(
      messageId: messageId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      createdAt: DateTime.now(),
      isRead: false,
      isDeleted: false,
      replyToMessageId: replyToMessageId,
      replyToText: replyToText,
      imageUrl: imageUrl,
    );

    await _db.collection("messages").doc(messageId).set(msg.toMap());
  }

  // MARK MESSAGES AS READ
  Future<void> markMessagesAsRead(String senderId) async {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return;

    // Get all unread messages from this sender
    final unreadMessages = await _db
        .collection("messages")
        .where("senderId", isEqualTo: senderId)
        .where("receiverId", isEqualTo: currentId)
        .where("isRead", isEqualTo: false)
        .get();

    if (unreadMessages.docs.isEmpty) return;

    // Batch update all messages as read
    final batch = _db.batch();
    final now = DateTime.now();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        "isRead": true,
        "readAt": Timestamp.fromDate(now),
      });
    }
    await batch.commit();
  }

  // DELETE MESSAGE (soft delete - only for sender)
  Future<void> deleteMessage(String messageId) async {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return;

    final messageRef = _db.collection("messages").doc(messageId);
    final messageDoc = await messageRef.get();

    if (!messageDoc.exists) return;

    final messageData = messageDoc.data()!;
    final senderId = messageData["senderId"] as String;

    // Only sender can delete their own messages
    if (senderId == currentId) {
      // Soft delete - mark as deleted instead of removing
      await messageRef.update({"isDeleted": true});
    }
  }

  // DELETE MESSAGE FOR EVERYONE (hard delete)
  Future<void> deleteMessageForEveryone(String messageId) async {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return;

    final messageRef = _db.collection("messages").doc(messageId);
    final messageDoc = await messageRef.get();

    if (!messageDoc.exists) return;

    final messageData = messageDoc.data()!;
    final senderId = messageData["senderId"] as String;

    // Only sender can delete for everyone
    if (senderId == currentId) {
      // Hard delete - completely remove the message
      await messageRef.delete();
    }
  }

  // SET TYPING STATUS
  Future<void> setTypingStatus(String receiverId, bool isTyping) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) return;

    final typingRef = _db.collection("typing").doc("${senderId}_$receiverId");

    if (isTyping) {
      await typingRef.set({
        "senderId": senderId,
        "receiverId": receiverId,
        "isTyping": true,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } else {
      await typingRef.delete();
    }
  }

  // GET TYPING STATUS
  Stream<bool> getTypingStatus(String userId) {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return Stream.value(false);

    return _db
        .collection("typing")
        .doc("${userId}_$currentId")
        .snapshots()
        .map(
          (snapshot) => snapshot.exists && snapshot.data()?["isTyping"] == true,
        );
  }

  // GET UNREAD COUNT FOR A CONVERSATION
  Future<int> getUnreadCount(String userId) async {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return 0;

    final unreadSnapshot = await _db
        .collection("messages")
        .where("senderId", isEqualTo: userId)
        .where("receiverId", isEqualTo: currentId)
        .where("isRead", isEqualTo: false)
        .where("isDeleted", isEqualTo: false)
        .get();

    return unreadSnapshot.docs.length;
  }

  // GET CHAT THREAD
  Stream<List<ChatMessage>> getMessages(String userId) {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) {
      return const Stream.empty();
    }

    // Mark messages as read when opening chat
    markMessagesAsRead(userId);

    // Query 1: Messages where current user is sender and userId is receiver
    final stream1 = _db
        .collection("messages")
        .where("senderId", isEqualTo: currentId)
        .where("receiverId", isEqualTo: userId)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  data["messageId"] = doc.id;
                  return ChatMessage.fromMap(data);
                } catch (e) {
                  print("Error parsing message ${doc.id}: $e");
                  return null;
                }
              })
              .whereType<ChatMessage>()
              .where((msg) => !msg.isDeleted) // Filter out deleted messages
              .toList();
        });

    // Query 2: Messages where userId is sender and current user is receiver
    final stream2 = _db
        .collection("messages")
        .where("senderId", isEqualTo: userId)
        .where("receiverId", isEqualTo: currentId)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  data["messageId"] = doc.id;
                  return ChatMessage.fromMap(data);
                } catch (e) {
                  print("Error parsing message ${doc.id}: $e");
                  return null;
                }
              })
              .whereType<ChatMessage>()
              .where((msg) => !msg.isDeleted) // Filter out deleted messages
              .toList();
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

  // GET CONVERSATIONS LIST (for MessagesPage)
  Stream<List<Map<String, dynamic>>> getConversations() {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) {
      return const Stream.empty();
    }

    // Get all messages where current user is sender or receiver
    return _db
        .collection("messages")
        .where("senderId", isEqualTo: currentId)
        .snapshots()
        .asyncMap((snapshot) async {
          final conversations = <String, Map<String, dynamic>>{};

          // Process messages where current user is sender
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final receiverId = data["receiverId"] as String;
            final isDeleted = data["isDeleted"] as bool? ?? false;

            if (isDeleted) continue;

            if (!conversations.containsKey(receiverId)) {
              final unreadCount = await getUnreadCount(receiverId);
              conversations[receiverId] = {
                "userId": receiverId,
                "lastMessage": data["text"] as String? ?? "",
                "lastMessageTime":
                    (data["createdAt"] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                "unreadCount": unreadCount,
              };
            } else {
              final existingTime =
                  conversations[receiverId]!["lastMessageTime"] as DateTime;
              final messageTime =
                  (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now();
              if (messageTime.isAfter(existingTime)) {
                final unreadCount = await getUnreadCount(receiverId);
                conversations[receiverId]!["lastMessage"] =
                    data["text"] as String? ?? "";
                conversations[receiverId]!["lastMessageTime"] = messageTime;
                conversations[receiverId]!["unreadCount"] = unreadCount;
              }
            }
          }

          // Also get messages where current user is receiver
          final receivedSnapshot = await _db
              .collection("messages")
              .where("receiverId", isEqualTo: currentId)
              .get();

          for (var doc in receivedSnapshot.docs) {
            final data = doc.data();
            final senderId = data["senderId"] as String;
            final messageTime =
                (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now();
            final isDeleted = data["isDeleted"] as bool? ?? false;

            if (isDeleted) continue;

            if (!conversations.containsKey(senderId)) {
              final unreadCount = await getUnreadCount(senderId);
              conversations[senderId] = {
                "userId": senderId,
                "lastMessage": data["text"] as String? ?? "",
                "lastMessageTime": messageTime,
                "unreadCount": unreadCount,
              };
            } else {
              final existingTime =
                  conversations[senderId]!["lastMessageTime"] as DateTime;
              if (messageTime.isAfter(existingTime)) {
                final unreadCount = await getUnreadCount(senderId);
                conversations[senderId]!["lastMessage"] =
                    data["text"] as String? ?? "";
                conversations[senderId]!["lastMessageTime"] = messageTime;
                conversations[senderId]!["unreadCount"] = unreadCount;
              }
            }
          }

          // Sort by last message time (newest first)
          final sortedConversations = conversations.values.toList()
            ..sort((a, b) {
              final timeA = a["lastMessageTime"] as DateTime;
              final timeB = b["lastMessageTime"] as DateTime;
              return timeB.compareTo(timeA);
            });

          return sortedConversations;
        });
  }
}
