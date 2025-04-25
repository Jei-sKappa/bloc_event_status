import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

typedef _MapData<TEvent, TStatus> = ({
  TStatus? status,
  StreamController<EventStatusUpdate<TEvent, TStatus>> streamController,
});

typedef EventStatusUpdate<TEvent, TStatus> = ({
  TEvent event,
  TStatus status,
});

@visibleForTesting
class BlocEventStatusContainer<TEvent, TState, TStatus> {
  BlocEventStatusContainer(this._bloc);

  final Bloc<TEvent, TState> _bloc;

  // Retrieved only by type
  final Map<Type, _MapData<TEvent, TStatus>> _eventStatusMap = {};

  TStatus? _lastStatusOfAllEvents;

  final _allEventStatusStreamController =
      StreamController<EventStatusUpdate<TEvent, TStatus>>.broadcast();

  _MapData<TEventSubType, TStatus>
      _getEventStatusMapValue<TEventSubType extends TEvent>() {
    // TODO: throw ArgumentError instead
    assert(TEventSubType != TEvent, 'The type parameter cannot be TEvent');

    return _eventStatusMap.putIfAbsent(TEventSubType, _ifAbsent<TEventSubType>)
        as _MapData<TEventSubType, TStatus>;
  }

  _MapData<TEventSubType, TStatus> _ifAbsent<TEventSubType extends TEvent>() =>
      (
        status: null,
        streamController: StreamController<
            EventStatusUpdate<TEventSubType, TStatus>>.broadcast()
      );

  void _updateStatusInMap<TEventSubType extends TEvent>(TStatus status) {
    final record = _getEventStatusMapValue<TEventSubType>();

    _eventStatusMap[TEventSubType] = (
      // Update the status
      status: status,
      // Keep the stream controller as is
      streamController: record.streamController,
    );
  }

  TStatus? statusOfAllEvents() {
    return _lastStatusOfAllEvents;
  }

  Stream<EventStatusUpdate<TEvent, TStatus>> streamStatusOfAllEvents() =>
      _allEventStatusStreamController.stream;

  TStatus? statusOf<TEventSubType extends TEvent>() {
    return _getEventStatusMapValue<TEventSubType>().status;
  }

  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusOf<TEventSubType extends TEvent>() {
    return _getEventStatusMapValue<TEventSubType>().streamController.stream;
  }

  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status,
  ) {
    try {
      if (_bloc.isClosed) {
        throw StateError('Cannot emit new states after calling close');
      }

      // This is wrong
      //// if (status == statusOf<TEventSubType>()) return;

      // Update the status
      _updateStatusInMap<TEventSubType>(status);

      // Update the last status
      _lastStatusOfAllEvents = status;

      // Add the status to the stream
      final streamController =
          _getEventStatusMapValue<TEventSubType>().streamController;
      if (!streamController.isClosed) {
        streamController.add((
          event: event,
          status: status,
        ));
      }

      // Add the event with the status to the event-specific streamcontroller
      if (!_allEventStatusStreamController.isClosed) {
        _allEventStatusStreamController.add((
          event: event,
          status: status,
        ));
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
    _allEventStatusStreamController.close();
    // Single events
    for (final record in _eventStatusMap.values) {
      await record.streamController.close();
    }
    _eventStatusMap.clear();
    await _bloc.close();
  }
}
