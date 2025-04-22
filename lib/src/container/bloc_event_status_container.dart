import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef _EventStatusRecord<TStatus> = ({
  TStatus? status,
  StreamController<TStatus> streamController,
});

@visibleForTesting
class BlocEventStatusContainer<TEvent, TState, TStatus> {
  BlocEventStatusContainer(this._bloc);

  final Bloc<TEvent, TState> _bloc;

  // Retrieved only by type
  final Map<Type, _EventStatusRecord<TStatus>> _singleInstanceEventsStatusMap =
      {};
  // Retrieved by type and event
  final Map<TEvent, _EventStatusRecord<TStatus>> _multiInstanceEventsStatusMap =
      {};

  _EventStatusRecord<TStatus> _ifAbsent() =>
      (status: null, streamController: StreamController<TStatus>.broadcast());

  TStatus? statusOf<TEventSubType extends TEvent>([TEventSubType? event]) {
    assert(TEventSubType != dynamic, 'The type must be specified');
    assert(TEventSubType != TEvent,
        'The specified type must be a subtype of TEvent');
    if (event != null) {
      return _multiInstanceEventsStatusMap[event]?.status;
    } else {
      return _singleInstanceEventsStatusMap[TEventSubType]?.status;
    }
  }

  Stream<TStatus> streamStatusOf<TEventSubType extends TEvent>(
      [TEventSubType? event]) {
    assert(TEventSubType != dynamic, 'The type must be specified');
    assert(TEventSubType != TEvent,
        'The specified type must be a subtype of TEvent');
    if (event != null) {
      return _multiInstanceEventsStatusMap
          .putIfAbsent(event, _ifAbsent)
          .streamController
          .stream;
    } else {
      return _singleInstanceEventsStatusMap
          .putIfAbsent(TEventSubType, _ifAbsent)
          .streamController
          .stream;
    }
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

      StreamController<TStatus> streamController;

      if (allowMultipleInstances) {
        streamController = _multiInstanceEventsStatusMap
            .putIfAbsent(event, _ifAbsent)
            .streamController;
        _multiInstanceEventsStatusMap[event] = (
          status: status,
          streamController: streamController,
        );
      } else {
        streamController = _singleInstanceEventsStatusMap
            .putIfAbsent(event.runtimeType, _ifAbsent)
            .streamController;
        _singleInstanceEventsStatusMap[event.runtimeType] = (
          status: status,
          streamController: streamController,
        );
      }

      if (!streamController.isClosed) {
        streamController.add(status);
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
