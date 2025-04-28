// ignore_reason: Use it only for testing
// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

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

// Mock Listener Callback
class MockListener<TEvent> extends Mock {
  void call(BuildContext context, TEvent event, EventStatus status);
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
  // Register fakes before any tests run
  setUpAll(() {
    registerFakes();
    registerFallbackValue(EventA(''));
    registerFallbackValue(EventB(-1));
    registerFallbackValue(const LoadingEventStatus());
  });

  group('MultiBlocEventStatusListener', () {
    late TestBloc testBloc;
    late MockListener<TestEvent> listener;

    setUp(() {
      testBloc = TestBloc();
      listener = MockListener<TestEvent>();

      when(() => listener(any(), any(), any())).thenReturn(null);
    });

    tearDown(() async {
      await testBloc.close();
    });

    testWidgets('renders child correctly', (tester) async {
      const testKey = Key('my_child_widget');
      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call,
            child: const SizedBox(key: testKey),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('calls listener when status changes', (tester) async {
      final eventA = EventA('event A data');
      final eventB = EventB(123);

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call,
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitLoadingStatus(eventA);
      await tester.pump();
      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);

      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pump();
      verify(() => listener(any(), eventB, const SuccessEventStatus<Null>()))
          .called(1);

      testBloc.emitFailureStatus(eventA);
      await tester.pump();
      verify(() => listener(any(), eventA, const FailureEventStatus()))
          .called(1);
    });

    testWidgets('calls listener when status changes and filter is true',
        (tester) async {
      final eventA1 = EventA('accept');
      final eventA2 = EventA('reject');
      final eventB1 = EventB(10);
      final eventB2 = EventB(5);

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call,
            // Filter that accepts specific instances of different subtypes
            filter: (event) {
              if (event is EventA) return event.data == 'accept';
              if (event is EventB) return event.data > 5;
              return false;
            },
            child: const SizedBox(),
          ),
        ),
      );

      // Emit matching EventA
      testBloc.emitLoadingStatus(eventA1);
      await tester.pump();
      verify(() => listener(any(), eventA1, const LoadingEventStatus()))
          .called(1);

      // Emit non-matching EventA
      testBloc.emitSuccessStatus<EventA, Null>(eventA2);
      await tester.pump();
      verifyNever(
        () => listener(any(), eventA2, const SuccessEventStatus<Null>()),
      );

      // Emit matching EventB
      testBloc.emitLoadingStatus(eventB1);
      await tester.pump();
      verify(() => listener(any(), eventB1, const LoadingEventStatus()))
          .called(1);

      // Emit non-matching EventB
      testBloc.emitFailureStatus(eventB2);
      await tester.pump();
      verifyNever(() => listener(any(), eventB2, const FailureEventStatus()));
    });

    testWidgets('does not call listener when filter returns false',
        (tester) async {
      final eventA = EventA('event A');
      final eventB = EventB(1);

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call,
            // Only allow EventA
            filter: (event) => event is EventA,
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitLoadingStatus(eventA);
      await tester.pump();
      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);

      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pump();
      // Listener should not be called for eventB
      verifyNever(
        () => listener(any(), eventB, const SuccessEventStatus<Null>()),
      );
    });

    testWidgets('does not call listener when listenWhen returns false',
        (tester) async {
      final eventA = EventA('event A');
      final eventB = EventB(2);

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call,
            // Only listen when status changes from loading to success
            listenWhen: (prev, current) =>
                prev == const LoadingEventStatus() &&
                current == const SuccessEventStatus<Null>(),
            child: const SizedBox(),
          ),
        ),
      );

      // First update: initial -> loading (listenWhen is false)
      testBloc.emitLoadingStatus(eventA);
      await tester.pump();
      verifyNever(() => listener(any(), eventA, const LoadingEventStatus()));

      // Second update: loading -> success (listenWhen is true)
      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pump();
      verify(() => listener(any(), eventB, const SuccessEventStatus<Null>()))
          .called(1);

      // Third update: success -> failure (listenWhen is false)
      testBloc.emitFailureStatus(eventA);
      await tester.pump();
      verifyNever(() => listener(any(), eventA, const FailureEventStatus()));
    });

    testWidgets('uses bloc from context if bloc parameter is null',
        (tester) async {
      final eventA = EventA('event A');

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call, // No bloc explicitly provided
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitLoadingStatus(eventA);
      await tester.pump();

      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);
    });

    testWidgets('uses provided bloc parameter if available', (tester) async {
      final eventA = EventA('event A');
      final eventB = EventB(3);
      final providedBloc = TestBloc();
      addTearDown(() async => providedBloc.close());

      await tester.pumpWidget(
        BlocProvider.value(
          // This bloc should be ignored
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            bloc: providedBloc, // Use this specific bloc
            listener: listener.call,
            child: const SizedBox(),
          ),
        ),
      );

      // Emit from the provided bloc's stream
      providedBloc.emitLoadingStatus(eventA);
      await tester.pump();
      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);

      // Emit from the context bloc's stream (should be ignored)
      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pump();
      verifyNever(
        () => listener(any(), eventB, const SuccessEventStatus<Null>()),
      );
    });

    testWidgets('updates subscription when bloc instance changes',
        (tester) async {
      final eventA = EventA('event A');
      final eventB = EventB(4);

      // Initial Bloc
      final blocA = TestBloc();
      addTearDown(() async => blocA.close());

      // New Bloc
      final blocB = TestBloc();
      addTearDown(() async => blocB.close());

      // Build with Bloc A
      await tester.pumpWidget(
        MultiBlocEventStatusListener<TestBloc, TestEvent>(
          bloc: blocA,
          listener: listener.call,
          child: const SizedBox(),
        ),
      );

      blocA.emitLoadingStatus(eventA);
      await tester.pump();
      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);

      // Rebuild with Bloc B
      await tester.pumpWidget(
        MultiBlocEventStatusListener<TestBloc, TestEvent>(
          bloc: blocB, // Switch to Bloc B
          listener: listener.call,
          child: const SizedBox(),
        ),
      );

      // Emit from Bloc A's stream (should be ignored now)
      blocA.emitFailureStatus(eventA);
      await tester.pump();
      verifyNever(() => listener(any(), eventA, const FailureEventStatus()));

      // Emit from Bloc B's stream (should be listened to)
      blocB.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pump();
      verify(() => listener(any(), eventB, const SuccessEventStatus<Null>()))
          .called(1);
    });

    testWidgets('handles initial status correctly in listenWhen',
        (tester) async {
      final eventA = EventA('event A');
      EventStatus? capturedPreviousStatus;
      EventStatus? capturedCurrentStatus;

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: MultiBlocEventStatusListener<TestBloc, TestEvent>(
            listener: listener.call,
            listenWhen: (prev, current) {
              capturedPreviousStatus = prev;
              capturedCurrentStatus = current;
              return true; // Always listen for verification
            },
            child: const SizedBox(),
          ),
        ),
      );

      // First update
      testBloc.emitLoadingStatus(eventA);
      await tester.pump();

      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);
      // Previous should be null initially
      expect(capturedPreviousStatus, isNull);
      expect(capturedCurrentStatus, const LoadingEventStatus());

      // Second update
      final eventB = EventB(5);
      testBloc.emitSuccessStatus<EventB, Null>(eventB);
      await tester.pump();

      verify(() => listener(any(), eventB, const SuccessEventStatus<Null>()))
          .called(1);
      // Now previous status should be the one from the last emission
      expect(capturedPreviousStatus, const LoadingEventStatus());
      expect(capturedCurrentStatus, const SuccessEventStatus<Null>());
    });

    testWidgets('unsubscribes on dispose', (tester) async {
      final eventA = EventA('event A');

      final mockBloc = MockBloc();

      // Use a real StreamController to check listeners
      final controller = StreamController<
          EventStatusUpdate<TestEvent, EventStatus>>.broadcast();
      when(mockBloc.streamStatusOfAllEvents).thenAnswer(
        (_) => controller.stream,
      );
      final specificControllerA =
          StreamController<EventStatusUpdate<EventA, EventStatus>>.broadcast();
      when(() => mockBloc.streamStatusOf<EventA>()).thenAnswer(
        (_) => specificControllerA.stream,
      );

      addTearDown(() async {
        await controller.close();
        await specificControllerA.close();
      });

      // Build the widget
      await tester.pumpWidget(
        MultiBlocEventStatusListener<MockBloc, TestEvent>(
          bloc: mockBloc,
          listener: listener.call,
          child: const SizedBox(),
        ),
      );

      // Check initial listener count on the 'all events' stream
      expect(controller.hasListener, isTrue);

      // Emit an event via the controller the listener IS subscribed to
      controller.add((event: eventA, status: const LoadingEventStatus()));
      await tester.pump(); // Let stream emit
      await tester.pump(); // Let listener react

      // Since we directly added to the stream, the listener should react
      verify(() => listener(any(), eventA, const LoadingEventStatus()))
          .called(1);

      // Remove the widget
      await tester.pumpWidget(const SizedBox());

      // Check listener count after dispose
      expect(controller.hasListener, isFalse);

      // Emit another event, listener should NOT be called
      controller.add((event: eventA, status: const SuccessEventStatus<Null>()));
      await tester.pump();
      verifyNever(
        () => listener(any(), eventA, const SuccessEventStatus<Null>()),
      );
    });
  });
}
