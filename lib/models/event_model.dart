import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final List<String> attendees;

  EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.attendees,
  });

  Map<String, dynamic> toMap() {
    return {
      "eventId": eventId,
      "title": title,
      "description": description,
      "location": location,
      "date": Timestamp.fromDate(date),
      "attendees": attendees,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      eventId: map["eventId"] as String,
      title: map["title"] as String,
      description: map["description"] as String,
      location: map["location"] as String,
      date: (map["date"] as Timestamp).toDate(),
      attendees: List<String>.from(map["attendees"] ?? []),
    );
  }
}
