import 'dart:async';

import 'package:bloc_event_status/src/helpers/cached_stream_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CachedStreamController', () {
    late StreamController<int> innerController;
    late CachedStreamController<int> cachedController;

    setUp(() {
      innerController = StreamController<int>();
      cachedController = CachedStreamController(innerController);
    });

    tearDown(() {
      cachedController.close();
    });

    test('add updates lastEvent', () {
      expect(cachedController.lastEvent, isNull);
      cachedController.add(1);
      expect(cachedController.lastEvent, 1);
      cachedController.add(2);
      expect(cachedController.lastEvent, 2);
    });

    test('delegates onListen, onCancel, onPause, onResume', () {
      var onListenCalled = false;
      var onCancelCalled = false;
      var onPauseCalled = false;
      var onResumeCalled = false;

      cachedController
        ..onListen = (() => onListenCalled = true)
        ..onCancel = (() => onCancelCalled = true)
        ..onPause = (() => onPauseCalled = true)
        ..onResume = (() => onResumeCalled = true);

      // Verify getters return what we set
      expect(cachedController.onListen, isNotNull);
      expect(cachedController.onCancel, isNotNull);
      expect(cachedController.onPause, isNotNull);
      expect(cachedController.onResume, isNotNull);

      // Trigger callbacks via inner controller mechanics
      final sub = cachedController.stream.listen((_) {});
      expect(onListenCalled, isTrue);

      sub.pause();
      expect(onPauseCalled, isTrue);

      sub.resume();
      expect(onResumeCalled, isTrue);

      sub.cancel();
      expect(onCancelCalled, isTrue);
    });

    test('delegates addError', () async {
      final error = Exception('test');
      scheduleMicrotask(() => cachedController.addError(error));
      expect(cachedController.stream, emitsError(error));
    });

    test('delegates addStream', () async {
      final stream = Stream.fromIterable([1, 2, 3]);
      // We don't await here because we want to verify stream emission
      unawaited(cachedController.addStream(stream));
      expect(cachedController.stream, emitsInOrder([1, 2, 3]));
    });

    test('delegates getters', () async {
      expect(cachedController.hasListener, isFalse);
      final sub = cachedController.stream.listen((_) {});
      expect(cachedController.hasListener, isTrue);

      expect(cachedController.isPaused, isFalse);
      sub.pause();
      expect(cachedController.isPaused, isTrue);
      sub.resume();

      expect(cachedController.isClosed, isFalse);
      await cachedController.close();
      expect(cachedController.isClosed, isTrue);

      expect(cachedController.done, isA<Future<dynamic>>());

      expect(cachedController.sink, isNotNull);

      unawaited(sub.cancel());
    });
  });
}
