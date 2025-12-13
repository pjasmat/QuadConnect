import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import 'event_details_page.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Events"),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService().getEvents(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final events = snapshot.data!;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                title: Text(e.title),
                subtitle: Text(e.location),
                trailing: Text(e.date.toString().substring(0, 16)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailsPage(event: e),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
