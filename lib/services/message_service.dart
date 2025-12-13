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

    return _db
        .collection("messages")
        .where("senderId", whereIn: [currentId, userId])
        .where("receiverId", whereIn: [currentId, userId])
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ChatMessage.fromMap(doc.data())).toList());
  }
}
