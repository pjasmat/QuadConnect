import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final String? imageUrl; // For image messages
  final String? replyToMessageId; // ID of message being replied to
  final String? replyToText; // Preview of replied message text

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    this.imageUrl,
    this.replyToMessageId,
    this.replyToText,
  });

  Map<String, dynamic> toMap() {
    return {
      "messageId": messageId,
      "senderId": senderId,
      "receiverId": receiverId,
      "text": text,
      "createdAt": Timestamp.fromDate(createdAt),
      "isRead": isRead,
      "readAt": readAt != null ? Timestamp.fromDate(readAt!) : null,
      "isDeleted": isDeleted,
      "imageUrl": imageUrl,
      "replyToMessageId": replyToMessageId,
      "replyToText": replyToText,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Handle createdAt field
    DateTime createdAt;
    if (map["createdAt"] == null) {
      createdAt = DateTime.now();
    } else if (map["createdAt"] is Timestamp) {
      createdAt = (map["createdAt"] as Timestamp).toDate();
    } else if (map["createdAt"] is DateTime) {
      createdAt = map["createdAt"] as DateTime;
    } else {
      createdAt = DateTime.now();
    }

    // Handle readAt field
    DateTime? readAt;
    if (map["readAt"] != null) {
      if (map["readAt"] is Timestamp) {
        readAt = (map["readAt"] as Timestamp).toDate();
      } else if (map["readAt"] is DateTime) {
        readAt = map["readAt"] as DateTime;
      }
    }

    return ChatMessage(
      messageId: map["messageId"] ?? "",
      senderId: map["senderId"] ?? "",
      receiverId: map["receiverId"] ?? "",
      text: map["text"] ?? "",
      createdAt: createdAt,
      isRead: map["isRead"] ?? false,
      readAt: readAt,
      isDeleted: map["isDeleted"] ?? false,
      imageUrl: map["imageUrl"],
      replyToMessageId: map["replyToMessageId"],
      replyToText: map["replyToText"],
    );
  }
}
