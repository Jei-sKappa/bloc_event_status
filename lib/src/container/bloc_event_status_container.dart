import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

typedef PreviousCurrentStatusPair<TStatus> = ({
  TStatus? previousStatus,
  TStatus status,
});

typedef _EventStatusStreamControllerRecord<TStatus> = ({
  TStatus? previousStatus,
  TStatus? status,
  StreamController<PreviousCurrentStatusPair<TStatus>> streamController,
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

  _EventStatusStreamControllerRecord<TStatus> _ifAbsent() => (
        previousStatus: null,
        status: null,
        streamController:
            StreamController<PreviousCurrentStatusPair<TStatus>>.broadcast()
      );

  void _updateSingleInstanceStatus(Type eventType, TStatus status) {
    final record =
        _singleInstanceEventsStatusMap.putIfAbsent(eventType, _ifAbsent);

    _singleInstanceEventsStatusMap[eventType] = (
      // Set the status to previous status
      previousStatus: record.status,
      // Update the status
      status: status,
      // Keep the stream controller as is
      streamController: record.streamController,
    );
  }

  void _updateMultiInstanceStatus(TEvent event, TStatus status) {
    final record = _multiInstanceEventsStatusMap.putIfAbsent(event, _ifAbsent);

    _multiInstanceEventsStatusMap[event] = (
      // Set the status to previous status
      previousStatus: record.status,
      // Update the status
      status: status,
      // Keep the stream controller as is
      streamController: record.streamController,
    );
  }

  TStatus? previousStatusOf<TEventSubType extends TEvent>(
      [TEventSubType? event]) {
    if (event != null) {
      return previousStatusFromEvent(event);
    } else {
      return previousStatusFromType(TEventSubType);
    }
  }

  @visibleForTesting
  TStatus? previousStatusFromType(Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type must be specified');
    assert(eventType != TEvent, 'The specified type cannot be $TEvent itself');
    // TODO: Check if the type is a subtype of TEvent
    return _singleInstanceEventsStatusMap
        .putIfAbsent(eventType, _ifAbsent)
        .previousStatus;
  }

  @visibleForTesting
  TStatus? previousStatusFromEvent<TEventSubType extends TEvent>(
      TEventSubType event) {
    assert(TEventSubType != Null, 'The type cannot be null');
    assert(TEventSubType != dynamic, 'The type must be specified');
    assert(
        TEventSubType != TEvent, 'The specified type cannot be $TEvent itself');

    return _multiInstanceEventsStatusMap
        .putIfAbsent(event, _ifAbsent)
        .previousStatus;
  }

  TStatus? statusOf<TEventSubType extends TEvent>([TEventSubType? event]) {
    if (event != null) {
      return statusFromEvent(event);
    } else {
      return statusFromType(TEventSubType);
    }
  }

  @visibleForTesting
  TStatus? statusFromType(Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type must be specified');
    assert(eventType != TEvent, 'The specified type cannot be $TEvent itself');
    // TODO: Check if the type is a subtype of TEvent
    return _singleInstanceEventsStatusMap
        .putIfAbsent(eventType, _ifAbsent)
        .status;
  }

  @visibleForTesting
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

  @visibleForTesting
  Stream<TStatus> streamStatusFromType(Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type must be specified');
    assert(eventType != TEvent, 'The specified type cannot be $TEvent itself');
    // TODO: Check if the type is a subtype of TEvent
    return _singleInstanceEventsStatusMap
        .putIfAbsent(eventType, _ifAbsent)
        .streamController
        .stream
        .map((pair) => pair.status);
  }

  @visibleForTesting
  Stream<TStatus> streamStatusFromEvent<TEventSubType extends TEvent>(
      TEventSubType event) {
    assert(TEventSubType != Null, 'The type cannot be null');
    assert(TEventSubType != dynamic, 'The type must be specified');
    assert(
        TEventSubType != TEvent, 'The specified type cannot be $TEvent itself');

    return _multiInstanceEventsStatusMap
        .putIfAbsent(event, _ifAbsent)
        .streamController
        .stream
        .map((pair) => pair.status);
  }

  Stream<PreviousCurrentStatusPair<TStatus>>
      streamStatusWithPreviousOf<TEventSubType extends TEvent>(
          [TEventSubType? event]) {
    if (event != null) {
      return streamStatusWithPreviousFromEvent(event);
    } else {
      return streamStatusWithPreviousFromType(TEventSubType);
    }
  }

  @visibleForTesting
  Stream<PreviousCurrentStatusPair<TStatus>> streamStatusWithPreviousFromType(
      Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type must be specified');
    assert(eventType != TEvent, 'The specified type cannot be $TEvent itself');
    // TODO: Check if the type is a subtype of TEvent
    return _singleInstanceEventsStatusMap
        .putIfAbsent(eventType, _ifAbsent)
        .streamController
        .stream;
  }

  @visibleForTesting
  Stream<PreviousCurrentStatusPair<TStatus>>
      streamStatusWithPreviousFromEvent<TEventSubType extends TEvent>(
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
        // Update the status
        _updateMultiInstanceStatus(event, status);

        // Add the status to the stream
        final record =
            _multiInstanceEventsStatusMap.putIfAbsent(event, _ifAbsent);
        final streamController = record.streamController;
        if (!streamController.isClosed) {
          streamController.add((
            previousStatus: record.previousStatus,
            status: status,
          ));
        }

        // Add the event with the status to the multi instance stream
        if (!_multiInstanceStreamController!.isClosed) {
          _multiInstanceStreamController!.add((event: event, status: status));
        }
      } else {
        // Update the status
        _updateSingleInstanceStatus(event.runtimeType, status);

        // Add the status to the stream
        final record = _singleInstanceEventsStatusMap.putIfAbsent(
            event.runtimeType, _ifAbsent);
        final streamController = record.streamController;
        if (!streamController.isClosed) {
          streamController.add((
            previousStatus: record.previousStatus,
            status: status,
          ));
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
