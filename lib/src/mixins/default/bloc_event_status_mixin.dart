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
  EventStatus? statusOf<TEventSubType extends TEvent>([TEventSubType? event]) =>
      getContainer().statusOf(event);

  @override
  @internal
  EventStatus? statusFromType(Type eventType) =>
      getContainer().statusFromType(eventType);

  @override
  @internal
  EventStatus? statusFromEvent<TEventSubType extends TEvent>(
          TEventSubType event) =>
      getContainer().statusFromEvent(event);

  @override
  Stream<EventStatus> streamStatusOf<TEventSubType extends TEvent>(
          [TEventSubType? event]) =>
      getContainer().streamStatusOf(event);

  @override
  @internal
  Stream<EventStatus> streamStatusFromType(Type eventType) =>
      getContainer().streamStatusFromType(eventType);

  @override
  @internal
  Stream<EventStatus> streamStatusFromEvent<TEventSubType extends TEvent>(
          TEventSubType event) =>
      getContainer().streamStatusFromEvent(event);

  @override
  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    EventStatus status, {
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(
        event,
        status,
        allowMultipleInstances: allowMultipleInstances,
      );

  @protected
  void emitLoadingStatus<TEventSubType extends TEvent>(
    TEventSubType event, {
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(
        event,
        LoadingEventStatus(),
        allowMultipleInstances: allowMultipleInstances,
      );

  @protected
  void emitFailureStatus<TEventSubType extends TEvent>(
    TEventSubType event, {
    Object? error,
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(
        event,
        FailureEventStatus(error),
        allowMultipleInstances: allowMultipleInstances,
      );

  @protected
  void emitSuccessStatus<TEventSubType extends TEvent>(
    TEventSubType event, {
    Object? data,
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(
        event,
        SuccessEventStatus(data),
        allowMultipleInstances: allowMultipleInstances,
      );

  EventHandler<TEventSubType, TState>
      handleEventStatus<TEventSubType extends TEvent>(
    EventHandler<TEventSubType, TState> eventHandler, {
    bool allowMultipleInstances = false,
    bool emitLoading = true,
    bool emitSuccess = true,
    bool emitFailure = true,
  }) =>
          (event, emit) async {
            if (emitLoading) emitLoadingStatus(event);
            try {
              await eventHandler(event, emit);
              if (emitSuccess) emitSuccessStatus(event);
            } catch (e) {
              if (emitFailure) emitFailureStatus(event, error: e);
            }
          };

  @override
  @mustCallSuper
  // `super.close()` is called in the `BlocEventStatusContainer.close()`
  // method
  // ignore: must_call_super
  Future<void> close() async => getContainer().close();
}
