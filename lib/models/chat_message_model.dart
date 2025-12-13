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
      "createdAt": createdAt,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      messageId: map["messageId"],
      senderId: map["senderId"],
      receiverId: map["receiverId"],
      text: map["text"],
      createdAt: map["createdAt"].toDate(),
    );
  }
}
