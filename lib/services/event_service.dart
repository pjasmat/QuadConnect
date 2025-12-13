import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // CREATE EVENT
  Future<void> createEvent(String title, String desc, String loc, DateTime date) async {
    final eventId = _db.collection("events").doc().id;

    final event = EventModel(
      eventId: eventId,
      title: title,
      description: desc,
      location: loc,
      date: date,
      attendees: [],
    );

    await _db.collection("events").doc(eventId).set(event.toMap());
  }

  // RSVP
  Future<void> toggleRSVP(String eventId, List attendees) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    if (attendees.contains(uid)) {
      await _db.collection("events").doc(eventId).update({
        "attendees": FieldValue.arrayRemove([uid])
      });
    } else {
      await _db.collection("events").doc(eventId).update({
        "attendees": FieldValue.arrayUnion([uid])
      });
    }
  }

  // GET EVENTS REAL TIME
  Stream<List<EventModel>> getEvents() {
    return _db
        .collection("events")
        .orderBy("date")
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EventModel.fromMap(doc.data()))
            .toList());
  }
}
