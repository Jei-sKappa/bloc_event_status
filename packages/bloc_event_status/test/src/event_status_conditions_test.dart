import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

sealed class Status {}

@immutable
class LoadingStatus extends Status {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LoadingStatus;

  @override
  int get hashCode => runtimeType.hashCode;
}

@immutable
class SuccessStatus extends Status {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SuccessStatus;

  @override
  int get hashCode => runtimeType.hashCode;
}

@immutable
class FailureStatus extends Status {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FailureStatus;

  @override
  int get hashCode => runtimeType.hashCode;
}

sealed class Event {}

@immutable
class EventA extends Event {
  EventA(this.id);
  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventA && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class EventB extends Event {
  EventB(this.value);
  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventB &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class TestState with EventStatusesMixin<Event, Status> {
  const TestState({this.eventStatuses = const EventStatuses()});

  @override
  final EventStatuses<Event, Status> eventStatuses;

  TestState copyWith({EventStatuses<Event, Status>? eventStatuses}) =>
      TestState(eventStatuses: eventStatuses ?? this.eventStatuses);
}

void main() {
  group('EventStatusConditions', () {
    late TestState empty;

    setUp(() {
      empty = const TestState();
    });

    group('statusChanged', () {
      test('returns false when both states are empty', () {
        expect(empty.statusChanged<EventA>(empty), isFalse);
      });

      test('returns true when status appears (null → value)', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(empty.statusChanged<EventA>(current), isTrue);
      });

      test('returns true when status type changes', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        expect(previous.statusChanged<EventA>(current), isTrue);
      });

      test('returns false when status is the same', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('2'),
            LoadingStatus(),
          ),
        );
        // Status is the same (LoadingStatus == LoadingStatus), even though
        // the event instance differs.
        expect(previous.statusChanged<EventA>(current), isFalse);
      });

      test('is symmetric', () {
        final a = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final b = a.copyWith(
          eventStatuses: a.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        expect(a.statusChanged<EventA>(b), b.statusChanged<EventA>(a));
      });

      test('does not cross event types', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(empty.statusChanged<EventB>(current), isFalse);
      });
    });

    group('eventStatusChanged', () {
      test('returns false when both states are empty', () {
        expect(empty.eventStatusChanged<EventA>(empty), isFalse);
      });

      test('returns true when event status appears', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(empty.eventStatusChanged<EventA>(current), isTrue);
      });

      test('returns true when event instance changes (same status)', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('2'),
            LoadingStatus(),
          ),
        );
        // Unlike statusChanged, this detects the different event instance.
        expect(previous.eventStatusChanged<EventA>(current), isTrue);
      });

      test('returns false when event status record is identical', () {
        final state = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        // Same state on both sides.
        expect(state.eventStatusChanged<EventA>(state), isFalse);
      });

      test('does not cross event types', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(empty.eventStatusChanged<EventB>(current), isFalse);
      });
    });

    group('statusChangedTo', () {
      test('returns true when status changes to the matched type', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        expect(
          previous.statusChangedTo<EventA, SuccessStatus>(current),
          isTrue,
        );
      });

      test('returns false when status changes but not to the matched type', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        expect(
          previous.statusChangedTo<EventA, SuccessStatus>(current),
          isFalse,
        );
      });

      test('returns false when status has not changed', () {
        final state = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        expect(state.statusChangedTo<EventA, SuccessStatus>(state), isFalse);
      });

      test('returns true when status appears and matches (null → match)', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(empty.statusChangedTo<EventA, LoadingStatus>(current), isTrue);
      });
    });

    group('eventStatusChangedTo', () {
      test('returns true when record changes and status matches', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        expect(
          previous.eventStatusChangedTo<EventA, FailureStatus>(current),
          isTrue,
        );
      });

      test('returns true when event instance changes and status matches', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('2'),
            FailureStatus(),
          ),
        );
        // statusChangedTo would return false (same status type),
        // but eventStatusChangedTo detects the different event instance.
        expect(
          previous.eventStatusChangedTo<EventA, FailureStatus>(current),
          isTrue,
        );
      });

      test('returns false when record changes but status does not match', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        expect(
          previous.eventStatusChangedTo<EventA, FailureStatus>(current),
          isFalse,
        );
      });

      test('returns false when record has not changed', () {
        final state = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        expect(
          state.eventStatusChangedTo<EventA, FailureStatus>(state),
          isFalse,
        );
      });

      test('returns true when record appears and status matches', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        expect(
          empty.eventStatusChangedTo<EventA, FailureStatus>(current),
          isTrue,
        );
      });

      test('returns false when record appears but status does not match', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(
          empty.eventStatusChangedTo<EventA, FailureStatus>(current),
          isFalse,
        );
      });
    });

    group('lastEventStatusChanged', () {
      test('returns false when both states are empty', () {
        expect(empty.lastEventStatusChanged(empty), isFalse);
      });

      test('returns true when last event status appears', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(empty.lastEventStatusChanged(current), isTrue);
      });

      test('returns true when last event status changes', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventB>(
            EventB(42),
            SuccessStatus(),
          ),
        );
        expect(previous.lastEventStatusChanged(current), isTrue);
      });

      test('returns false when last event status is the same', () {
        final state = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        expect(state.lastEventStatusChanged(state), isFalse);
      });
    });

    group('lastEventStatusChangedTo', () {
      test('returns true when last event status changes and matches', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        expect(
          previous.lastEventStatusChangedTo<FailureStatus>(current),
          isTrue,
        );
      });

      test(
        'returns false when last event status changes but does not match',
        () {
          final previous = empty.copyWith(
            eventStatuses: empty.eventStatuses.update<EventA>(
              EventA('1'),
              LoadingStatus(),
            ),
          );
          final current = previous.copyWith(
            eventStatuses: previous.eventStatuses.update<EventA>(
              EventA('1'),
              SuccessStatus(),
            ),
          );
          expect(
            previous.lastEventStatusChangedTo<FailureStatus>(current),
            isFalse,
          );
        },
      );

      test('returns false when last event status has not changed', () {
        final state = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        expect(state.lastEventStatusChangedTo<FailureStatus>(state), isFalse);
      });

      test(
        'returns true when last event status appears and matches',
        () {
          final current = empty.copyWith(
            eventStatuses: empty.eventStatuses.update<EventA>(
              EventA('1'),
              FailureStatus(),
            ),
          );
          expect(
            empty.lastEventStatusChangedTo<FailureStatus>(current),
            isTrue,
          );
        },
      );

      test(
        'returns false when last event status appears but does not match',
        () {
          final current = empty.copyWith(
            eventStatuses: empty.eventStatuses.update<EventA>(
              EventA('1'),
              LoadingStatus(),
            ),
          );
          expect(
            empty.lastEventStatusChangedTo<FailureStatus>(current),
            isFalse,
          );
        },
      );

      test('returns false when current lastEventStatus is null', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            FailureStatus(),
          ),
        );
        // current is empty → lastEventStatus is null
        expect(
          previous.lastEventStatusChangedTo<FailureStatus>(empty),
          isFalse,
        );
      });
    });

    group('composition', () {
      test('multiple statusChanged with || (Pattern 2)', () {
        final current = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventB>(
            EventB(1),
            SuccessStatus(),
          ),
        );
        // EventA did not change, but EventB did.
        final result = empty.statusChanged<EventA>(current) ||
            empty.statusChanged<EventB>(current);
        expect(result, isTrue);
      });

      test('multiple eventStatusChangedTo with || (Pattern 4)', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        final result =
            previous.eventStatusChangedTo<EventA, SuccessStatus>(current) ||
                previous.eventStatusChangedTo<EventB, SuccessStatus>(current);
        expect(result, isTrue);
      });

      test('eventStatusChanged combined with manual check', () {
        final previous = empty.copyWith(
          eventStatuses: empty.eventStatuses.update<EventA>(
            EventA('1'),
            LoadingStatus(),
          ),
        );
        final current = previous.copyWith(
          eventStatuses: previous.eventStatuses.update<EventA>(
            EventA('1'),
            SuccessStatus(),
          ),
        );
        final result = previous.eventStatusChanged<EventA>(current) &&
            current.statusOf<EventA>() is SuccessStatus;
        expect(result, isTrue);
      });
    });
  });
}
