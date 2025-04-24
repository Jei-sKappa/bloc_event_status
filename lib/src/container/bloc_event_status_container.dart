import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

typedef _MapData<TEvent, TStatus> = ({
  TStatus? previousStatus,
  TStatus? status,
  StreamController<EventStatusUpdate<TEvent, TStatus>> streamController,
});

typedef EventStatusUpdate<TEvent, TStatus> = ({
  TEvent event,
  TStatus? previousStatus,
  TStatus status,
});

@visibleForTesting
class BlocEventStatusContainer<TEvent, TState, TStatus> {
  BlocEventStatusContainer(this._bloc) {
    _eventTypeStatusStreamController =
        StreamController<EventStatusUpdate<TEvent, TStatus>>.broadcast();

    _eventInstanceStreamController =
        StreamController<EventStatusUpdate<TEvent, TStatus>>.broadcast();
  }

  final Bloc<TEvent, TState> _bloc;

  // Retrieved only by type
  final Map<Type, _MapData<TEvent, TStatus>> _eventTypeStatusMap = {};

  // Retrieved by type and event
  final Map<TEvent, _MapData<TEvent, TStatus>> _eventInstanceStatusMap = {};

  StreamController<EventStatusUpdate<TEvent, TStatus>>?
      _eventTypeStatusStreamController;

  StreamController<EventStatusUpdate<TEvent, TStatus>>?
      _eventInstanceStreamController;

  _MapData<TEventSubType, TStatus>
      _getEventTypeStatusMapValue<TEventSubType extends TEvent>(
          Type eventType) {
    assert(eventType != Null, 'The type cannot be null');
    assert(eventType != dynamic, 'The type cannot be dynamic');
    assert(eventType != TEvent, 'The provided eventType cannot be TEvent');
    assert(TEventSubType != TEvent, 'The type parameter cannot be TEvent');
    assert(eventType == TEventSubType,
        'The type must be the same as the eventType ($eventType), currently: $TEventSubType');

    return _eventTypeStatusMap.putIfAbsent(eventType, _ifAbsent<TEventSubType>)
        as _MapData<TEventSubType, TStatus>;
  }

  _MapData<TEventSubType, TStatus>
      _getEventInstanceStatusMapValue<TEventSubType extends TEvent>(
          TEventSubType event) {
    return _eventInstanceStatusMap.putIfAbsent(event, _ifAbsent<TEventSubType>)
        as _MapData<TEventSubType, TStatus>;
  }

  _MapData<TEventSubType, TStatus> _ifAbsent<TEventSubType extends TEvent>() => (
        previousStatus: null,
        status: null,
        streamController: StreamController<
            EventStatusUpdate<TEventSubType, TStatus>>.broadcast()
      );

  void _updateSingleInstanceStatus<TEventSubType extends TEvent>(
      Type eventType, TStatus status) {
    final record = _getEventTypeStatusMapValue<TEventSubType>(eventType);

    _eventTypeStatusMap[eventType] = (
      // Set the status to previous status
      previousStatus: record.status,
      // Update the status
      status: status,
      // Keep the stream controller as is
      streamController: record.streamController,
    );
  }

  void _updateMultiInstanceStatus<TEventSubType extends TEvent>(
      TEventSubType event, TStatus status) {
    final record = _getEventInstanceStatusMapValue<TEventSubType>(event);

    _eventInstanceStatusMap[event] = (
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
      return previousStatusFromEvent<TEventSubType>(event);
    } else {
      return previousStatusFromType<TEventSubType>(TEventSubType);
    }
  }

  @visibleForTesting
  TStatus? previousStatusFromType<TEventSubType extends TEvent>(
      Type eventType) {
    return _getEventTypeStatusMapValue<TEventSubType>(eventType).previousStatus;
  }

  @visibleForTesting
  TStatus? previousStatusFromEvent<TEventSubType extends TEvent>(
      TEventSubType event) {
    return _getEventInstanceStatusMapValue<TEventSubType>(event).previousStatus;
  }

  TStatus? statusOf<TEventSubType extends TEvent>([TEventSubType? event]) {
    if (event != null) {
      return statusFromEvent<TEventSubType>(event);
    } else {
      return statusFromType<TEventSubType>(TEventSubType);
    }
  }

  @visibleForTesting
  TStatus? statusFromType<TEventSubType extends TEvent>(Type eventType) {
    return _getEventTypeStatusMapValue<TEventSubType>(eventType).status;
  }

  @visibleForTesting
  TStatus? statusFromEvent<TEventSubType extends TEvent>(TEventSubType event) {
    return _getEventInstanceStatusMapValue<TEventSubType>(event).status;
  }

  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusOf<TEventSubType extends TEvent>([TEventSubType? event]) {
    if (event != null) {
      return streamStatusFromEvent<TEventSubType>(event);
    } else {
      return streamStatusFromType<TEventSubType>(TEventSubType);
    }
  }

  @visibleForTesting
  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusFromType<TEventSubType extends TEvent>(Type eventType) {
    return _getEventTypeStatusMapValue<TEventSubType>(eventType)
        .streamController
        .stream;
  }

  @visibleForTesting
  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusFromEvent<TEventSubType extends TEvent>(TEventSubType event) {
    return _getEventInstanceStatusMapValue<TEventSubType>(event)
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
        _updateMultiInstanceStatus<TEventSubType>(event, status);

        // Add the status to the stream
        final record = _getEventInstanceStatusMapValue<TEventSubType>(event);
        final streamController = record.streamController;
        if (!streamController.isClosed) {
          streamController.add((
            event: event,
            previousStatus: record.previousStatus,
            status: status,
          ));
        }

        // Add the event with the status to the multi instance stream
        if (!_eventInstanceStreamController!.isClosed) {
          _eventInstanceStreamController!.add((
            event: event,
            previousStatus: record.previousStatus,
            status: status,
          ));
        }
      } else {
        // Update the status
        _updateSingleInstanceStatus<TEventSubType>(event.runtimeType, status);

        // Add the status to the stream
        final record =
            _getEventTypeStatusMapValue<TEventSubType>(event.runtimeType);
        final streamController = record.streamController;
        if (!streamController.isClosed) {
          streamController.add((
            event: event,
            previousStatus: record.previousStatus,
            status: status,
          ));
        }

        // Add the event with the status to the single instance stream
        if (!_eventTypeStatusStreamController!.isClosed) {
          _eventTypeStatusStreamController!.add((
            event: event,
            previousStatus: record.previousStatus,
            status: status,
          ));
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
    for (final record in _eventTypeStatusMap.values) {
      await record.streamController.close();
    }
    _eventTypeStatusMap.clear();
    // Multi instance events
    for (final record in _eventInstanceStatusMap.values) {
      await record.streamController.close();
    }
    _eventInstanceStatusMap.clear();
    await _bloc.close();
  }
}
