import 'package:flutter_test/flutter_test.dart';
import 'package:quadconnect/models/event_model.dart';

void main() {
  group('EventModel Tests', () {
    test('EventModel should serialize and deserialize correctly', () {
      final event = EventModel(
        eventId: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        location: 'Test Location',
        date: DateTime(2024, 1, 1, 12, 0),
        attendees: ['user1', 'user2'],
        creatorId: 'creator1',
        category: 'Academic',
        tags: ['networking', 'workshop'],
        capacity: 50,
      );

      final map = event.toMap();
      final recreated = EventModel.fromMap(map);

      expect(recreated.eventId, equals(event.eventId));
      expect(recreated.title, equals(event.title));
      expect(recreated.description, equals(event.description));
      expect(recreated.location, equals(event.location));
      expect(recreated.category, equals(event.category));
      expect(recreated.tags, equals(event.tags));
      expect(recreated.capacity, equals(event.capacity));
      expect(recreated.attendees.length, equals(2));
    });

    test('EventModel should handle null optional fields', () {
      final event = EventModel(
        eventId: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        location: 'Test Location',
        date: DateTime(2024, 1, 1, 12, 0),
        attendees: [],
        creatorId: 'creator1',
      );

      expect(event.category, isNull);
      expect(event.tags, isEmpty);
      expect(event.capacity, isNull);
    });

    test('EventModel should handle capacity limits', () {
      final event = EventModel(
        eventId: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        location: 'Test Location',
        date: DateTime(2024, 1, 1, 12, 0),
        attendees: ['user1', 'user2', 'user3'],
        creatorId: 'creator1',
        capacity: 5,
      );

      expect(event.attendees.length, equals(3));
      expect(event.capacity, equals(5));
      expect(event.attendees.length < event.capacity!, isTrue);
    });
  });
}

