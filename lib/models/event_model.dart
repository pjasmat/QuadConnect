import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final List<String> attendees;
  final String creatorId; // Who created the event
  final String? imageUrl; // Optional event image
  final DateTime createdAt; // When event was created
  final String?
  category; // Event category (e.g., "Academic", "Social", "Sports", "Club")
  final List<String>
  tags; // Event tags (e.g., ["networking", "free-food", "workshop"])
  final int? capacity; // Max attendees (null = unlimited)

  EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.attendees,
    required this.creatorId,
    this.imageUrl,
    DateTime? createdAt,
    this.category,
    List<String>? tags,
    this.capacity,
  }) : createdAt = createdAt ?? DateTime.now(),
       tags = tags ?? [];

  Map<String, dynamic> toMap() {
    return {
      "eventId": eventId,
      "title": title,
      "description": description,
      "location": location,
      "date": Timestamp.fromDate(date),
      "attendees": attendees,
      "creatorId": creatorId,
      "imageUrl": imageUrl,
      "createdAt": Timestamp.fromDate(createdAt),
      "category": category,
      "tags": tags,
      "capacity": capacity,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    if (map["createdAt"] == null) {
      createdAt = DateTime.now();
    } else if (map["createdAt"] is Timestamp) {
      createdAt = (map["createdAt"] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }

    return EventModel(
      eventId: map["eventId"] as String? ?? "",
      title: map["title"] as String? ?? "",
      description: map["description"] as String? ?? "",
      location: map["location"] as String? ?? "",
      date: map["date"] != null
          ? (map["date"] as Timestamp).toDate()
          : DateTime.now(),
      attendees: List<String>.from(map["attendees"] ?? []),
      creatorId: map["creatorId"] as String? ?? "",
      imageUrl: map["imageUrl"] as String?,
      createdAt: createdAt,
      category: map["category"] as String?,
      tags: List<String>.from(map["tags"] ?? []),
      capacity: map["capacity"] as int?,
    );
  }
}
