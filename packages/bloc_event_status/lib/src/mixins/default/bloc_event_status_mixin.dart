import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

mixin BlocEventStatusMixin<TEvent, TState> on Bloc<TEvent, TState>
    implements BlocCustomEventStatusMixin<TEvent, TState, EventStatus> {
  BlocEventStatusContainer<TEvent, TState, EventStatus>? _container;

  @override
  BlocEventStatusContainer<TEvent, TState, EventStatus> getContainer() =>
      _container ??= BlocEventStatusContainer(this);

  @override
  EventStatus? statusOfAllEvents() => getContainer().statusOfAllEvents();

  @override
  Stream<EventStatusUpdate<TEvent, EventStatus>> streamAllEventStatus() =>
      getContainer().streamStatusOfAllEvents();

  @override
  EventStatus? statusOf<TEventSubType extends TEvent>() =>
      getContainer().statusOf<TEventSubType>();

  @override
  Stream<EventStatusUpdate<TEventSubType, EventStatus>>
      streamStatusOf<TEventSubType extends TEvent>() =>
          getContainer().streamStatusOf<TEventSubType>();

  @override
  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    EventStatus status,
  ) =>
      getContainer().emitEventStatus(
        event,
        status,
      );

  @protected
  void emitLoadingStatus<TEventSubType extends TEvent>(
    TEventSubType event, {
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(event, LoadingEventStatus());

  @protected
  void emitFailureStatus<TEventSubType extends TEvent>(
    TEventSubType event, {
    Object? error,
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(event, FailureEventStatus(error));

  @protected
  void emitSuccessStatus<TEventSubType extends TEvent>(
    TEventSubType event, {
    Object? data,
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(event, SuccessEventStatus(data));

  EventHandler<TEventSubType, TState>
      handleEventStatus<TEventSubType extends TEvent>(
    EventHandler<TEventSubType, TState> eventHandler, {
    bool emitLoading = true,
    bool emitSuccess = true,
    bool emitFailure = true,
  }) =>
          (event, emit) async {
            if (emitLoading) {
              emitLoadingStatus(event);
            }
            try {
              await eventHandler(event, emit);
              if (emitSuccess) {
                emitSuccessStatus(event);
              }
            } catch (e) {
              if (emitFailure) {
                emitFailureStatus(event, error: e);
              }
              addError(e, StackTrace.current);
            }
          };

  @override
  @mustCallSuper
  // `super.close()` is called in the `BlocEventStatusContainer.close()`
  // method
  // ignore: must_call_super
  Future<void> close() async => getContainer().close();
}
