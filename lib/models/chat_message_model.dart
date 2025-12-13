import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "messageId": messageId,
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Handle createdAt field - could be Timestamp or already DateTime
    DateTime createdAt;
    if (map["createdAt"] == null) {
      createdAt = DateTime.now();
    } else if (map["createdAt"] is Timestamp) {
      createdAt = (map["createdAt"] as Timestamp).toDate();
    } else if (map["createdAt"] is DateTime) {
      createdAt = map["createdAt"] as DateTime;
    } else {
      // Fallback to current time if unknown type
      createdAt = DateTime.now();
    }
    
    return ChatMessage(
      messageId: map["messageId"] ?? "",
      senderId: map["senderId"] ?? "",
      receiverId: map["receiverId"] ?? "",
      text: map["text"] ?? "",
      createdAt: createdAt,
    );
  }
}
