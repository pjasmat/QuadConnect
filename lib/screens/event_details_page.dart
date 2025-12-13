import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../widgets/share_bottom_sheet.dart';
import '../services/user_service.dart';
import 'edit_event_page.dart';
import 'profile_page.dart';

class EventDetailsPage extends StatefulWidget {
  final EventModel event;

  const EventDetailsPage({super.key, required this.event});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  late EventModel _event;
  final EventService _eventService = EventService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    // Reload event data to get latest attendees
    final eventDoc = await FirebaseFirestore.instance
        .collection('events')
        .doc(_event.eventId)
        .get();

    if (eventDoc.exists && mounted) {
      setState(() {
        _event = EventModel.fromMap(eventDoc.data()!);
      });
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _eventService.deleteEvent(_event.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditEventPage(event: _event)),
    );

    if (result == true && mounted) {
      await _loadEventData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = _eventService.currentUid;
    final isGoing = currentUid != null && _event.attendees.contains(currentUid);
    final isCreator = currentUid != null && _event.creatorId == currentUid;
    final isPast = _event.date.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isCreator) ...[
            IconButton(icon: const Icon(Icons.edit), onPressed: _editEvent),
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteEvent),
          ],
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => ShareBottomSheet(event: _event),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Status Badge
            if (isPast)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Past Event', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Category and Tags
            if (_event.category != null || _event.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_event.category != null)
                    Chip(
                      label: Text(_event.category!),
                      avatar: const Icon(Icons.category, size: 18),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                    ),
                  ..._event.tags.map(
                    (tag) => Chip(
                      label: Text(tag),
                      avatar: const Icon(Icons.tag, size: 16),
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Description
            Text(
              _event.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Event Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      _event.location,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.access_time,
                      'Date & Time',
                      DateFormat(
                        'EEEE, MMMM dd, yyyy • hh:mm a',
                      ).format(_event.date),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.people,
                      'Attendees',
                      _event.capacity != null
                          ? '${_event.attendees.length}/${_event.capacity} ${_event.attendees.length == 1 ? 'person' : 'people'} attending'
                          : '${_event.attendees.length} ${_event.attendees.length == 1 ? 'person' : 'people'} attending',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // RSVP Button
            if (!isPast && currentUid != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_event.capacity != null &&
                          _event.attendees.length >= _event.capacity! &&
                          !isGoing)
                      ? null // Disable if event is full and user is not already going
                      : () async {
                          try {
                            // Show loading indicator
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isGoing
                                            ? 'Cancelling RSVP...'
                                            : 'RSVPing to event...',
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }

                            // Toggle RSVP
                            await _eventService.toggleRSVP(_event.eventId);

                            // Reload event data to get updated attendees
                            await _loadEventData();

                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isGoing
                                        ? 'RSVP cancelled successfully'
                                        : 'RSVP confirmed!',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              String errorMessage = 'Unable to update RSVP';
                              if (e.toString().contains('full capacity')) {
                                errorMessage =
                                    'This event is at full capacity. Cannot RSVP.';
                              } else if (e.toString().contains(
                                'not logged in',
                              )) {
                                errorMessage =
                                    'Please log in to RSVP to events.';
                              } else if (e.toString().contains('not found')) {
                                errorMessage = 'This event no longer exists.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                  icon: Icon(
                    isGoing ? Icons.event_busy : Icons.event_available,
                  ),
                  label: Text(
                    isGoing
                        ? 'Cancel RSVP'
                        : (_event.capacity != null &&
                              _event.attendees.length >= _event.capacity!)
                        ? 'Event Full'
                        : 'RSVP to Event',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isGoing
                        ? Colors.grey
                        : (_event.capacity != null &&
                              _event.attendees.length >= _event.capacity!)
                        ? Colors.grey[400]
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Attendees List
            if (_event.attendees.isNotEmpty) ...[
              const Text(
                'Attendees',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getAttendeesStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final attendees = snapshot.data!;
                  if (attendees.isEmpty) {
                    return const Text('No attendees yet');
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendees.length,
                    itemBuilder: (context, index) {
                      final attendee = attendees[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: attendee['photoUrl'] != null
                              ? NetworkImage(attendee['photoUrl'] as String)
                              : null,
                          child: attendee['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(
                          attendee['username'] ?? attendee['name'] ?? 'Unknown',
                        ),
                        subtitle: Text(attendee['email']?.toString() ?? ''),
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 24),

            // Event Creator Card
            const Text(
              'Event Creator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>?>(
              future: _userService.getUser(_event.creatorId),
              builder: (context, creatorSnapshot) {
                if (creatorSnapshot.hasData && creatorSnapshot.data != null) {
                  final creator = creatorSnapshot.data!;
                  final creatorName =
                      creator['username'] ?? creator['name'] ?? 'Unknown User';
                  final creatorPhoto =
                      creator['photoUrl'] ?? creator['profilePicUrl'] ?? '';

                  return Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfilePage(userId: _event.creatorId),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: creatorPhoto.isNotEmpty
                                  ? (creatorPhoto.startsWith('data:image/')
                                        ? MemoryImage(
                                            base64Decode(
                                              creatorPhoto.split(',')[1],
                                            ),
                                          )
                                        : NetworkImage(creatorPhoto))
                                  : null,
                              child: creatorPhoto.isEmpty
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Created by ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        creatorName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tap to view profile',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isSecondary = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isSecondary
              ? Colors.grey[400]
              : Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSecondary ? 12 : 16,
                  fontWeight: FontWeight.w500,
                  color: isSecondary ? Colors.grey[600] : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> _getAttendeesStream() {
    if (_event.attendees.isEmpty) {
      return Stream.value([]);
    }

    return Stream.fromFuture(
      Future.wait(
        _event.attendees.map((uid) async {
          final userDoc = await _userService.getUser(uid);
          return userDoc ?? {'uid': uid, 'username': 'Unknown'};
        }),
      ),
    );
  }
}
