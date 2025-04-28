// ignore_reason: Use it only for testing
// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fakes.dart';

class MockBloc extends Mock
    implements BlocCustomEventStatusMixin<TestEvent, int, TestStatus> {}

// Test Bloc
class TestBloc extends Bloc<TestEvent, int>
    with BlocCustomEventStatusMixin<TestEvent, int, TestStatus> {
  TestBloc() : super(0) {
    on<EventA>((event, emit) {});
    on<EventB>((event, emit) {});
  }
}

// Mock Listener Callback
class MockListener<TEvent, TStatus> extends Mock {
  void call(BuildContext context, TEvent event, TStatus status);
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
}

// Test Status
enum TestStatus { initial, loading, success, failure }

void main() {
  group('BlocCustomEventStatusListener', () {
    late TestBloc testBloc;
    late MockListener<EventA, TestStatus> listener;

    setUpAll(() {
      registerFakes();
      registerFallbackValue(EventA(''));
      registerFallbackValue(EventB(-1));
      registerFallbackValue(TestStatus.initial);
    });

    setUp(() {
      testBloc = TestBloc();
      listener = MockListener<EventA, TestStatus>();

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
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            listener: listener.call,
            child: const SizedBox(key: testKey),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('calls listener when status changes', (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            listener: listener.call,
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump(); // Allow stream to emit
      verify(() => listener(any(), event1, TestStatus.loading)).called(1);

      testBloc.emitEventStatus(event2, TestStatus.success);
      await tester.pump(); // Allow stream to emit

      verify(() => listener(any(), event2, TestStatus.success)).called(1);
    });

    testWidgets('calls listener when status changes and filter is true',
        (tester) async {
      final event1 = EventA('event1');

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            listener: listener.call,
            filter: (event) => event.data == 'event1',
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();

      verify(() => listener(any(), event1, TestStatus.loading)).called(1);
    });

    testWidgets('does not call listener when filter returns false',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            listener: listener.call,
            // Only allow event1
            filter: (event) => event.data == 'event1',
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();
      verify(() => listener(any(), event1, TestStatus.loading)).called(1);

      testBloc.emitEventStatus(event2, TestStatus.success);
      await tester.pump();
      // Listener should not be called for event2
      verifyNever(() => listener(any(), event2, TestStatus.success));
    });

    testWidgets('does not call listener when listenWhen returns false',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            listener: listener.call,
            // Only listen when status changes from loading to success
            listenWhen: (prev, current) =>
                prev == TestStatus.loading && current == TestStatus.success,
            child: const SizedBox(),
          ),
        ),
      );

      // First update: initial -> loading (listenWhen is false)
      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();
      verifyNever(() => listener(any(), event1, TestStatus.loading));

      // Second update: loading -> success (listenWhen is true)
      testBloc.emitEventStatus(event2, TestStatus.success);
      await tester.pump();
      verify(() => listener(any(), event2, TestStatus.success)).called(1);

      // Third update: success -> failure (listenWhen is false)
      testBloc.emitEventStatus(event1, TestStatus.failure);
      await tester.pump();
      verifyNever(() => listener(any(), event1, TestStatus.failure));
    });

    testWidgets('uses bloc from context if bloc parameter is null',
        (tester) async {
      final event1 = EventA('event1');

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            listener: listener.call, // No bloc explicitly provided
            child: const SizedBox(),
          ),
        ),
      );

      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();

      verify(() => listener(any(), event1, TestStatus.loading)).called(1);
    });

    testWidgets('uses provided bloc parameter if available', (tester) async {
      final event1 = EventA('event1');
      final providedBloc = TestBloc();
      addTearDown(() async => providedBloc.close());

      await tester.pumpWidget(
        BlocProvider.value(
          // This bloc should be ignored
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            bloc: providedBloc,
            listener: listener.call,
            child: const SizedBox(),
          ),
        ),
      );

      // Emit from the provided bloc's stream
      providedBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();

      verify(() => listener(any(), event1, TestStatus.loading)).called(1);

      // Emit from the context bloc's stream (should be ignored)
      testBloc.emitEventStatus(event1, TestStatus.success);
      await tester.pump();
      verifyNever(() => listener(any(), event1, TestStatus.success));
    });

    testWidgets('updates subscription when bloc instance changes',
        (tester) async {
      final event1 = EventA('event1');
      final event2 = EventA('event2');

      // Initial Bloc
      final blocA = TestBloc();
      addTearDown(() async => blocA.close());

      // New Bloc
      final blocB = TestBloc();
      addTearDown(() async => blocB.close());

      // Build with Bloc A
      await tester.pumpWidget(
        BlocCustomEventStatusListener<TestBloc, TestEvent, EventA, TestStatus>(
          bloc: blocA,
          listener: listener.call,
          child: const SizedBox(),
        ),
      );

      blocA.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();
      verify(() => listener(any(), event1, TestStatus.loading)).called(1);

      // Rebuild with Bloc B
      await tester.pumpWidget(
        BlocCustomEventStatusListener<TestBloc, TestEvent, EventA, TestStatus>(
          bloc: blocB, // Switch to Bloc B
          listener: listener.call,
          child: const SizedBox(),
        ),
      );

      // Emit from Bloc A's stream (should be ignored now)
      blocA.emitEventStatus(event1, TestStatus.failure);
      await tester.pump();
      verifyNever(() => listener(any(), event1, TestStatus.failure));

      // Emit from Bloc B's stream (should be listened to)
      blocB.emitEventStatus(event2, TestStatus.success);
      await tester.pump();
      verify(() => listener(any(), event2, TestStatus.success)).called(1);
    });

    testWidgets('handles initial status correctly in listenWhen',
        (tester) async {
      final event1 = EventA('event1');
      TestStatus? capturedPreviousStatus;
      TestStatus? capturedCurrentStatus;

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
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
      testBloc.emitEventStatus(event1, TestStatus.loading);
      await tester.pump();

      verify(() => listener(any(), event1, TestStatus.loading)).called(1);
      // Previous should be null initially
      expect(capturedPreviousStatus, isNull);
      expect(capturedCurrentStatus, TestStatus.loading);
    });

    testWidgets('only listens to the specified event subtype', (tester) async {
      final subEvent = EventA('sub');
      final otherEvent = EventB(10); // Different subtype

      await tester.pumpWidget(
        BlocProvider.value(
          value: testBloc,
          child: BlocCustomEventStatusListener<TestBloc, TestEvent, EventA,
              TestStatus>(
            // Listening specifically for EventA
            listener: listener.call,
            child: const SizedBox(),
          ),
        ),
      );

      // Emit the correct subtype
      testBloc.emitEventStatus(subEvent, TestStatus.loading);
      await tester.pump();
      verify(() => listener(any(), subEvent, TestStatus.loading)).called(1);

      // Emit a different subtype (should be ignored by the listener)
      testBloc.emitEventStatus(otherEvent, TestStatus.success);
      await tester.pump();
      // Listener should not be called for EventB
      verifyNever(
        () => listener(any(), any(that: isA<EventB>()), any()),
      );
    });

    testWidgets('unsubscribes on dispose', (tester) async {
      final event1 = EventA('event1');

      final mockBloc = MockBloc();

      // Use a real StreamController to check listeners
      final controller =
          StreamController<EventStatusUpdate<EventA, TestStatus>>.broadcast();
      when(() => mockBloc.streamStatusOf<EventA>()).thenAnswer(
        (_) => controller.stream,
      );
      addTearDown(() async => controller.close());

      // Build the widget
      await tester.pumpWidget(
        BlocCustomEventStatusListener<MockBloc, TestEvent, EventA, TestStatus>(
          bloc: mockBloc,
          listener: listener.call,
          child: const SizedBox(),
        ),
      );

      // Check initial listener count
      expect(controller.hasListener, isTrue);

      // Emit an event, listener should be called
      controller.add((event: event1, status: TestStatus.loading));
      await tester.pump();
      verify(() => listener(any(), event1, TestStatus.loading)).called(1);

      // Remove the widget
      await tester.pumpWidget(const SizedBox());

      // Check listener count after dispose
      expect(controller.hasListener, isFalse);

      // Emit another event, listener should NOT be called
      controller.add((event: event1, status: TestStatus.success));
      await tester.pump();
      verifyNever(() => listener(any(), event1, TestStatus.success));
    });
  });
}
