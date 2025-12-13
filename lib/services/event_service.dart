import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import 'notification_helper.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // CREATE EVENT
  Future<void> createEvent(
    String title,
    String desc,
    String loc,
    DateTime date, {
    String? imageUrl,
    String? category,
    List<String>? tags,
    int? capacity,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final eventId = _db.collection("events").doc().id;

    final event = EventModel(
      eventId: eventId,
      title: title,
      description: desc,
      location: loc,
      date: date,
      attendees: [],
      creatorId: uid,
      imageUrl: imageUrl,
      category: category,
      tags: tags,
      capacity: capacity,
    );

    await _db.collection("events").doc(eventId).set(event.toMap());

    // Notify followers about new event
    try {
      final notificationHelper = NotificationHelper();
      await notificationHelper.notifyNewEvent(eventId, title);
    } catch (e) {
      // Log error but don't fail the event creation
      print('Error sending event notification: $e');
    }
  }

  // UPDATE EVENT
  Future<void> updateEvent(
    String eventId,
    String title,
    String desc,
    String loc,
    DateTime date, {
    String? imageUrl,
    String? category,
    List<String>? tags,
    int? capacity,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final eventRef = _db.collection("events").doc(eventId);
    final eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      throw Exception('Event not found');
    }

    final eventData = eventDoc.data()!;
    if (eventData["creatorId"] != uid) {
      throw Exception('You can only edit events you created');
    }

    await eventRef.update({
      "title": title,
      "description": desc,
      "location": loc,
      "date": Timestamp.fromDate(date),
      if (imageUrl != null) "imageUrl": imageUrl,
      "category": category,
      "tags": tags ?? [],
      "capacity": capacity,
    });
  }

  // DELETE EVENT
  Future<void> deleteEvent(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final eventRef = _db.collection("events").doc(eventId);
    final eventDoc = await eventRef.get();

    if (!eventDoc.exists) {
      throw Exception('Event not found');
    }

    final eventData = eventDoc.data()!;
    if (eventData["creatorId"] != uid) {
      throw Exception('You can only delete events you created');
    }

    await eventRef.delete();
  }

  // RSVP - Toggle RSVP status
  Future<void> toggleRSVP(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    try {
      // Get current event data
      final eventDoc = await _db.collection("events").doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data()!;
      final attendees = List<String>.from(eventData['attendees'] ?? []);
      final capacity = eventData['capacity'] as int?;

      // Check if user is already attending
      if (attendees.contains(uid)) {
        // Remove from attendees
        await _db.collection("events").doc(eventId).update({
          "attendees": FieldValue.arrayRemove([uid]),
        });
      } else {
        // Check capacity limit before adding
        if (capacity != null && attendees.length >= capacity) {
          throw Exception('Event is at full capacity. Cannot RSVP.');
        }
        // Add to attendees
        await _db.collection("events").doc(eventId).update({
          "attendees": FieldValue.arrayUnion([uid]),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle RSVP: $e');
    }
  }

  // GET EVENTS REAL TIME
  Stream<List<EventModel>> getEvents() {
    return _db
        .collection("events")
        .orderBy("date")
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => EventModel.fromMap(doc.data())).toList(),
        );
  }
}
