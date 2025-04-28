// ignore_reason: Use it only for testing
// ignore_for_file: invalid_use_of_protected_member

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fakes.dart';

class MockBloc extends Mock implements BlocEventStatusMixin<TestEvent, int> {}

// Test Bloc
class TestBloc extends Bloc<TestEvent, int>
    with BlocEventStatusMixin<TestEvent, int> {
  TestBloc() : super(0) {
    on<EventA>((event, emit) => emit(state + 1));
    on<EventB>((event, emit) => emit(state - 1));
  }
}

// Test Events
sealed class TestEvent {}

@immutable
class EventA extends TestEvent {
  EventA(this.data);
  final String data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventA && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'EventA(data: $data)';
}

@immutable
class EventB extends TestEvent {
  EventB(this.data);
  final int data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventB && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'EventB(data: $data)';
}

void main() {
  group('MultiBlocEventStatusBuilder', () {
    late TestBloc testBloc;

    setUpAll(() {
      registerFakes();
      registerFallbackValue(EventA(''));
      registerFallbackValue(EventB(-1));
      registerFallbackValue(const LoadingEventStatus());
    });

    setUp(() {
      testBloc = TestBloc();
    });

    tearDown(() async {
      await testBloc.close();
    });

    // Helper to create a standard builder for tests
    Widget testBuilder(
      BuildContext context,
      TestEvent? event,
      EventStatus? status,
    ) {
      final statusString = switch (status) {
        null => 'None',
        LoadingEventStatus() => 'loading',
        SuccessEventStatus() => 'success',
        FailureEventStatus() => 'failure',
      };
      final eventDesc = switch (event) {
        null => 'None',
        final EventA event => 'EventA(${event.data})',
        final EventB event => 'EventB(${event.data})',
      };
      return Text(
        'Event: $eventDesc, Status: $statusString',
      );
    }

    testWidgets('renders initial state correctly (event and status are null)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None'), findsOneWidget);
    });

    testWidgets(
        'rebuilds with correct event and status for different event types',
        (tester) async {
      final eventA = EventA('eventA');
      final eventB = EventB(123);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None'), findsOneWidget);

      testBloc.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(eventA), Status: loading'),
        findsOneWidget,
      );

      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventB(123), Status: success'),
        findsOneWidget,
      );
    });

    testWidgets('rebuilds when filter returns true', (tester) async {
      final eventA = EventA('allowed');
      final eventB = EventB(10); // Also allowed by filter

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                filter: (event) =>
                    (event is EventA && event.data == 'allowed') ||
                    (event is EventB && event.data == 10),
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      testBloc.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(allowed), Status: loading'),
        findsOneWidget,
      );

      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pumpAndSettle();
      expect(find.text('Event: EventB(10), Status: success'), findsOneWidget);
    });

    testWidgets('does not rebuild when filter returns false', (tester) async {
      final allowedEvent = EventA('allowed');
      final blockedEventA = EventA('blocked');
      final blockedEventB = EventB(99); // Also blocked by filter

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                // Only allow EventA with data 'allowed'
                filter: (event) => event is EventA && event.data == 'allowed',
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit allowed event - should rebuild
      testBloc.emitLoadingStatus(allowedEvent);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(allowed), Status: loading'),
        findsOneWidget,
      );

      // Emit blocked EventA - should NOT rebuild
      testBloc.emitSuccessStatus<EventA, Null>(blockedEventA);
      await tester.pumpAndSettle();
      // The widget should still show the previous state
      expect(
        find.text('Event: EventA(allowed), Status: loading'),
        findsOneWidget,
      );
      // The blocked event should not be shown
      expect(
        find.text('Event: EventA(blocked), Status: success'),
        findsNothing,
      );

      // Emit blocked EventB - should NOT rebuild
      testBloc.emitFailureStatus(blockedEventB);
      await tester.pumpAndSettle();
      // The widget should still show the previous state
      expect(
        find.text('Event: EventA(allowed), Status: loading'),
        findsOneWidget,
      );
      // The blocked event should not be shown
      expect(find.text('Event: EventB(99), Status: failure'), findsNothing);
    });

    testWidgets('rebuilds when buildWhen returns true', (tester) async {
      final eventA = EventA('eventA');
      final eventB = EventB(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                // Only rebuild when status changes to success
                buildWhen: (_, current) =>
                    current == const SuccessEventStatus<Null>(),
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit loading status (EventA)
      testBloc.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();
      // Should not have rebuilt yet
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit success status (EventB)
      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pumpAndSettle();
      // Should rebuild
      expect(find.text('Event: EventB(1), Status: success'), findsOneWidget);
    });

    testWidgets('does not rebuild when buildWhen returns false',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventB(2);
      final event3 = EventA('event3');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                // Only rebuild when status changes from loading to success
                buildWhen: (prev, current) =>
                    prev == const LoadingEventStatus() &&
                    current == const SuccessEventStatus<Null>(),
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // First update: initial -> loading (EventA)
      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();
      // Should not have rebuilt yet
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Second update: loading -> success (EventB)
      testBloc.emitSuccessStatus<EventB, Null>(event2);
      await tester.pumpAndSettle();
      // Should Rebuild
      expect(find.text('Event: EventB(2), Status: success'), findsOneWidget);

      // Third update: success -> failure (EventA)
      testBloc.emitFailureStatus(event3);
      await tester.pumpAndSettle();
      // Should not have rebuilt (should still show the previous state)
      expect(find.text('Event: EventB(2), Status: success'), findsOneWidget);
      // The failure event should not be shown
      expect(
        find.text('Event: EventA(event3), Status: failure'),
        findsNothing,
      );
    });

    testWidgets('uses bloc from context if bloc parameter is null',
        (tester) async {
      final eventA = EventA('eventA');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                // No bloc explicitly provided
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      testBloc.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();

      expect(
        find.text('Event: EventA(eventA), Status: loading'),
        findsOneWidget,
      );
    });

    testWidgets('uses provided bloc parameter if available', (tester) async {
      final eventA = EventA('eventA');
      final eventB = EventB(5);

      final contextBloc = TestBloc();
      addTearDown(() async => contextBloc.close());

      final providedBloc = TestBloc();
      addTearDown(() async => providedBloc.close());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: contextBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                bloc: providedBloc, // Explicitly provide the BLoC
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit from the provided bloc (EventA) - should rebuild
      providedBloc.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(eventA), Status: loading'),
        findsOneWidget,
      );

      // Emit from the context bloc (EventB) - should be ignored
      contextBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pumpAndSettle();
      // Builder should not have changed
      expect(
        find.text('Event: EventA(eventA), Status: loading'),
        findsOneWidget,
      );
      expect(find.text('Event: EventB(5), Status: success'), findsNothing);
    });

    testWidgets('updates subscription and rebuilds when bloc instance changes',
        (tester) async {
      final eventA = EventA('fromA');
      final eventB = EventB(10); // Event for Bloc B

      // Initial Bloc
      final blocA = TestBloc();
      addTearDown(() async => blocA.close());

      // New Bloc
      final blocB = TestBloc();
      addTearDown(() async => blocB.close());

      // Build with Bloc A
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
              bloc: blocA,
              builder: testBuilder,
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit from Bloc A - should rebuild
      blocA.emitLoadingStatus(eventA);
      await tester.pumpAndSettle();
      expect(
        find.text('Event: EventA(fromA), Status: loading'),
        findsOneWidget,
      );

      // Rebuild with Bloc B
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
              bloc: blocB, // Switch to Bloc B
              builder: testBuilder,
            ),
          ),
        ),
      );

      // NOTE: When the bloc instance changes, the state resets (_event=null, _status=null)
      // before the new bloc potentially emits.
      expect(find.text('Event: None, Status: None'), findsOneWidget);

      // Emit from Bloc A (should be ignored now)
      blocA.emitFailureStatus(EventA('ignored'));
      await tester.pumpAndSettle();
      // State should still be the reset state from the bloc change
      expect(find.text('Event: None, Status: None'), findsOneWidget);
      expect(
        find.text('Event: EventA(ignored), Status: failure'),
        findsNothing,
      );

      // Emit from Bloc B (should be listened to)
      blocB.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pumpAndSettle();
      expect(find.text('Event: EventB(10), Status: success'), findsOneWidget);
    });

    testWidgets(
        'handles initial status correctly in buildWhen (previous is null)',
        (tester) async {
      final event1 = EventB(1); // Use EventB for variety
      EventStatus? capturedPreviousStatus;
      EventStatus? capturedCurrentStatus;
      var buildWhenCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: testBloc,
              child: MultiBlocEventStatusBuilder<TestBloc, TestEvent, int>(
                buildWhen: (prev, current) {
                  buildWhenCalled = true;
                  capturedPreviousStatus = prev;
                  capturedCurrentStatus = current;
                  return true; // Always rebuild for verification
                },
                builder: testBuilder,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Event: None, Status: None'), findsOneWidget);
      // buildWhen not called on initial build
      expect(buildWhenCalled, isFalse);

      // First update
      testBloc.emitLoadingStatus(event1);
      await tester.pumpAndSettle();

      // buildWhen should have been called
      expect(buildWhenCalled, isTrue);
      // Previous should be null for the first emission
      expect(capturedPreviousStatus, isNull);
      expect(capturedCurrentStatus, const LoadingEventStatus());
      // Rebuilt
      expect(find.text('Event: EventB(1), Status: loading'), findsOneWidget);
    });
  });
}
