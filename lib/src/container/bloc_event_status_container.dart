import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

typedef _EventStatusStreamControllerRecord<TStatus> = ({
  TStatus? status,
  StreamController<TStatus> streamController,
});

typedef EventTypeStatusPair<TStatus> = ({Type eventType, TStatus status});

typedef EventStatusPair<TEvent, TStatus> = ({TEvent event, TStatus status});

@visibleForTesting
class BlocEventStatusContainer<TEvent, TState, TStatus> {
  BlocEventStatusContainer(this._bloc) {
    _singleInstanceStreamController =
        StreamController<EventTypeStatusPair>.broadcast();

    _multiInstanceStreamController =
        StreamController<EventStatusPair>.broadcast();
  }

  final Bloc<TEvent, TState> _bloc;

  // Retrieved only by type
  final Map<Type, _EventStatusStreamControllerRecord<TStatus>>
      _singleInstanceEventsStatusMap = {};
  // Retrieved by type and event
  final Map<TEvent, _EventStatusStreamControllerRecord<TStatus>>
      _multiInstanceEventsStatusMap = {};

  StreamController<EventTypeStatusPair>? _singleInstanceStreamController;

  StreamController<EventStatusPair>? _multiInstanceStreamController;

  _EventStatusStreamControllerRecord<TStatus> _ifAbsent() =>
      (status: null, streamController: StreamController<TStatus>.broadcast());

  TStatus? statusOf<TEventSubType extends TEvent>([TEventSubType? event]) {
    if (event != null) {
      return statusFromEvent(event);
    } else {
      return statusFromType(TEventSubType);
    }
  }

  @internal
  TStatus? statusFromType(Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type must be specified');
    assert(eventType != TEvent, 'The specified type cannot be $TEvent itself');
    // TODO: Check if the type is a subtype of TEvent
    return _singleInstanceEventsStatusMap
        .putIfAbsent(eventType, _ifAbsent)
        .status;
  }

  @internal
  TStatus? statusFromEvent<TEventSubType extends TEvent>(TEventSubType event) {
    assert(TEventSubType != Null, 'The type cannot be null');
    assert(TEventSubType != dynamic, 'The type must be specified');
    assert(
        TEventSubType != TEvent, 'The specified type cannot be $TEvent itself');

    return _multiInstanceEventsStatusMap.putIfAbsent(event, _ifAbsent).status;
  }

  Stream<TStatus> streamStatusOf<TEventSubType extends TEvent>(
      [TEventSubType? event]) {
    if (event != null) {
      return streamStatusFromEvent(event);
    } else {
      return streamStatusFromType(TEventSubType);
    }
  }

  @internal
  Stream<TStatus> streamStatusFromType(Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type must be specified');
    assert(eventType != TEvent, 'The specified type cannot be $TEvent itself');
    // TODO: Check if the type is a subtype of TEvent
    return _singleInstanceEventsStatusMap
        .putIfAbsent(eventType, _ifAbsent)
        .streamController
        .stream;
  }

  @internal
  Stream<TStatus> streamStatusFromEvent<TEventSubType extends TEvent>(
      TEventSubType event) {
    assert(TEventSubType != Null, 'The type cannot be null');
    assert(TEventSubType != dynamic, 'The type must be specified');
    assert(
        TEventSubType != TEvent, 'The specified type cannot be $TEvent itself');

    return _multiInstanceEventsStatusMap
        .putIfAbsent(event, _ifAbsent)
        .streamController
        .stream;
  }

  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status, {
    bool allowMultipleInstances = false,
  }) {
    try {
      if (_bloc.isClosed) {
        throw StateError('Cannot emit new states after calling close');
      }

      if (status == statusOf(event)) return;

      if (allowMultipleInstances) {
        final record =
            _multiInstanceEventsStatusMap.putIfAbsent(event, _ifAbsent);

        final streamController = record.streamController;

        // Update the status
        _multiInstanceEventsStatusMap[event] = (
          status: status,
          streamController: streamController,
        );

        // Add the status to the stream
        if (!streamController.isClosed) {
          streamController.add(status);
        }

        // Add the event with the status to the multi instance stream
        if (!_multiInstanceStreamController!.isClosed) {
          _multiInstanceStreamController!.add((event: event, status: status));
        }
      } else {
        final record = _singleInstanceEventsStatusMap.putIfAbsent(
            event.runtimeType, _ifAbsent);

        final streamController = record.streamController;

        // Update the status
        _singleInstanceEventsStatusMap[event.runtimeType] = (
          status: status,
          streamController: streamController,
        );

        // Add the status to the stream
        if (!streamController.isClosed) {
          streamController.add(status);
        }

        // Add the event with the status to the single instance stream
        if (!_singleInstanceStreamController!.isClosed) {
          _singleInstanceStreamController!.add(
            (eventType: event.runtimeType, status: status),
          );
        }
      }
    } catch (error, stackTrace) {
      // This class is wrapping a Bloc
      // ignore: invalid_use_of_protected_member
      _bloc.onError(error, stackTrace);
      rethrow;
    }
  }

  @mustCallSuper
  Future<void> close() async {
    // Single instance events
    for (final record in _singleInstanceEventsStatusMap.values) {
      await record.streamController.close();
    }
    _singleInstanceEventsStatusMap.clear();
    // Multi instance events
    for (final record in _multiInstanceEventsStatusMap.values) {
      await record.streamController.close();
    }
    _multiInstanceEventsStatusMap.clear();
    await _bloc.close();
  }
}
