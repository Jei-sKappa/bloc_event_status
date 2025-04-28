import 'dart:async';

import 'package:bloc_event_status/src/helpers/with_previous_stream_transformer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WithPrevious', () {
    test('emits pairs of previous and current values with initial value',
        () async {
      final controller = StreamController<int>();
      final stream = controller.stream;
      const initialValue = 0;

      final transformedStream = stream.transform(WithPrevious(initialValue));

      expect(
        transformedStream,
        emitsInOrder([
          (previous: initialValue, current: 1),
          (previous: 1, current: 2),
          (previous: 2, current: 3),
          emitsDone,
        ]),
      );

      controller
        ..add(1)
        ..add(2)
        ..add(3);

      await controller.close();
    });

    test('emits pairs of previous and current values without initial value',
        () async {
      final controller = StreamController<int>();
      final stream = controller.stream;

      final transformedStream = stream.transform(WithPrevious());

      expect(
        transformedStream,
        emitsInOrder([
          (previous: null, current: 1),
          (previous: 1, current: 2),
          (previous: 2, current: 3),
          emitsDone,
        ]),
      );

      controller
        ..add(1)
        ..add(2)
        ..add(3);

      await controller.close();
    });

    test('emits done when the source stream is empty', () async {
      final controller = StreamController<int>();
      final stream = controller.stream;

      final transformedStream = stream.transform(WithPrevious());

      expect(
        transformedStream,
        emitsDone,
      );

      await controller.close();
    });

    test('forwards errors from the source stream', () async {
      final controller = StreamController<int>();
      final stream = controller.stream;
      final error = Exception('some error');

      final transformedStream = stream.transform(WithPrevious<int>());

      expect(
        transformedStream,
        emitsInOrder([
          (previous: null, current: 1),
          emitsError(error),
          (previous: 1, current: 2),
          emitsDone,
        ]),
      );

      controller
        ..add(1)
        ..addError(error)
        ..add(2);

      await controller.close();
    });
  });
}
