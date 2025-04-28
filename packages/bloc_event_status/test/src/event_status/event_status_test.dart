// Testing without const
// ignore_for_file: prefer_const_constructors

import 'package:bloc_event_status/src/event_status/event_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadingEventStatus', () {
    test('supports value equality', () {
      expect(LoadingEventStatus(), equals(LoadingEventStatus()));
    });

    test('props are correct', () {
      expect(LoadingEventStatus().props, equals(<Object?>[]));
    });

    test('toString is correct', () {
      expect(
        LoadingEventStatus().toString(),
        equals('LoadingEventStatus()'),
      );
    });
  });

  group('SuccessEventStatus', () {
    test('supports value equality with data', () {
      expect(
        SuccessEventStatus('data'),
        equals(SuccessEventStatus('data')),
      );
    });

    test('supports value equality without data', () {
      expect(
        SuccessEventStatus<Null>(),
        equals(SuccessEventStatus<Null>()),
      );
    });

    test('props are correct with data', () {
      expect(
        SuccessEventStatus('data').props,
        equals(<Object?>['data']),
      );
    });

    test('props are correct without data', () {
      expect(
        SuccessEventStatus<Null>().props,
        equals(<Object?>[null]),
      );
    });

    test('toString is correct with data', () {
      expect(
        SuccessEventStatus<String>('data').toString(),
        equals('SuccessEventStatus(data)'),
      );
    });

    test('toString is correct without data', () {
      expect(
        SuccessEventStatus<String>().toString(),
        equals('SuccessEventStatus(null)'),
      );
    });
  });

  group('FailureEventStatus', () {
    final exception = Exception('error');

    test('supports value equality with error', () {
      expect(
        FailureEventStatus(exception),
        equals(FailureEventStatus(exception)),
      );
    });

    test('supports value equality without error', () {
      expect(
        FailureEventStatus(),
        equals(FailureEventStatus()),
      );
    });

    test('supports value equality with different error types', () {
      final customException = FormatException('format error');
      expect(
        FailureEventStatus(customException),
        equals(FailureEventStatus(customException)),
      );
    });

    test('props are correct with error', () {
      expect(
        FailureEventStatus(exception).props,
        equals(<Object?>[exception]),
      );
    });

    test('props are correct without error', () {
      expect(
        FailureEventStatus().props,
        equals(<Object?>[null]),
      );
    });

    test('toString is correct with error', () {
      expect(
        FailureEventStatus<Exception>(exception).toString(),
        equals('FailureEventStatus($exception)'),
      );
    });

    test('toString is correct without error', () {
      expect(
        FailureEventStatus<Exception>().toString(),
        equals('FailureEventStatus(null)'),
      );
    });
  });
}
