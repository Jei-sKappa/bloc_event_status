import 'package:bloc_event_status/bloc_event_status.dart';
// import 'package:meta/meta.dart';
import 'package:test/test.dart';

// Test Statuses
enum TestStatus { initial, loading, success, failure }

// Test Events
sealed class Event {}

// @immutable
// class EventA extends Event {
//   EventA(this.id);

//   final String id;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is EventA && runtimeType == other.runtimeType && id == other.id;

//   @override
//   int get hashCode => id.hashCode;
// }

// @immutable
// class EventB extends Event {
//   EventB(this.value);
//   final int value;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is EventB &&
//           runtimeType == other.runtimeType &&
//           value == other.value;

//   @override
//   int get hashCode => value.hashCode;
// }

void main() {
  group('EventStatuses', () {
    late EventStatuses<Event, TestStatus> eventStatuses;

    setUp(() {
      eventStatuses = const EventStatuses();
    });

    test('initially empty', () {
      expect(eventStatuses.eventStatusMap, isEmpty);
      expect(eventStatuses.lastEventStatus, isNull);
    });

    // TODO: Add missing tests
  });
}
