import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';
import 'event_details_page.dart';
import 'create_event_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _filter = 'all'; // 'all', 'upcoming', 'past'
  final EventService _eventService = EventService();

  List<EventModel> _filterEvents(List<EventModel> events) {
    final now = DateTime.now();
    switch (_filter) {
      case 'upcoming':
        return events.where((e) => e.date.isAfter(now)).toList();
      case 'past':
        return events.where((e) => e.date.isBefore(now)).toList();
      default:
        return events;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Events"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateEventPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('all', 'All Events'),
                _buildFilterChip('upcoming', 'Upcoming'),
                _buildFilterChip('past', 'Past'),
              ],
            ),
          ),
          const Divider(height: 1),
          // Events List
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _eventService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEvents = snapshot.data!;
                final filteredEvents = _filterEvents(allEvents);

                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filter == 'upcoming'
                              ? Icons.event_busy
                              : _filter == 'past'
                              ? Icons.history
                              : Icons.event_note,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'upcoming'
                              ? 'No upcoming events'
                              : _filter == 'past'
                              ? 'No past events'
                              : 'No events yet',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_filter == 'all')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CreateEventPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Event'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final isPast = event.date.isBefore(DateTime.now());
                    final currentUid = _eventService.currentUid;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .doc(event.eventId)
                          .snapshots(),
                      builder: (context, eventSnapshot) {
                        if (!eventSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final eventData =
                            eventSnapshot.data!.data() as Map<String, dynamic>?;
                        final attendees = List<String>.from(
                          eventData?['attendees'] ?? [],
                        );
                        final isGoing =
                            currentUid != null &&
                            attendees.contains(currentUid);
                        final attendeeCount = attendees.length;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPast
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                                  child: const Icon(
                                    Icons.event,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  event.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isPast
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat(
                                            'MMM dd, yyyy • hh:mm a',
                                          ).format(event.date),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.people, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$attendeeCount ${attendeeCount == 1 ? 'person' : 'people'} attending',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: isPast
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.grey,
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                      ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EventDetailsPage(event: event),
                                    ),
                                  );
                                },
                              ),
                              // RSVP Button (only for upcoming events)
                              if (!isPast && currentUid != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await _eventService.toggleRSVP(
                                            event.eventId,
                                          );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  isGoing
                                                      ? 'RSVP cancelled'
                                                      : 'RSVP confirmed!',
                                                ),
                                                backgroundColor: Colors.green,
                                                duration: const Duration(
                                                  seconds: 1,
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: Icon(
                                        isGoing
                                            ? Icons.event_busy
                                            : Icons.event_available,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isGoing ? 'Cancel RSVP' : 'RSVP',
                                        style: TextStyle(
                                          color: isGoing
                                              ? (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Colors.grey)
                                              : (Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.white
                                                  : Theme.of(context).primaryColor),
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: isGoing
                                              ? Colors.grey
                                              : Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}
