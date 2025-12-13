import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class EventDetailsPage extends StatefulWidget {
  final EventModel event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late EventModel _event;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _eventService.currentUid;
    final isGoing = currentUid != null && _event.attendees.contains(currentUid);

    return Scaffold(
      appBar: AppBar(title: Text(_event.title)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_event.description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 15),
            Text("Location: ${_event.location}"),
            const SizedBox(height: 10),
            Text("Date: ${_event.date}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: currentUid == null
                  ? null
                  : () async {
                      final updatedAttendees = List<String>.from(_event.attendees);
                      if (isGoing) {
                        updatedAttendees.remove(currentUid);
                      } else {
                        updatedAttendees.add(currentUid);
                      }
                      setState(() {
                        _event = EventModel(
                          eventId: _event.eventId,
                          title: _event.title,
                          description: _event.description,
                          location: _event.location,
                          date: _event.date,
                          attendees: updatedAttendees,
                        );
                      });
                      await _eventService.toggleRSVP(
                        _event.eventId,
                        updatedAttendees,
                      );
                    },
              child: Text(isGoing ? "Cancel RSVP" : "RSVP"),
            )
          ],
        ),
      ),
    );
  }
}
