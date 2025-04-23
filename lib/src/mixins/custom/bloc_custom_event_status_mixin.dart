import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

mixin BlocCustomEventStatusMixin<TEvent, TState, TStatus>
    on Bloc<TEvent, TState> {
  BlocEventStatusContainer<TEvent, TState, TStatus>? _container;

  BlocEventStatusContainer<TEvent, TState, TStatus> getContainer() =>
      _container ??= BlocEventStatusContainer(this);

  TStatus? previousStatusOf<TEventSubType extends TEvent>(
      [TEventSubType? event]) => getContainer().previousStatusOf(event);

  @internal
  TStatus? previousStatusFromType(Type eventType) =>
      getContainer().previousStatusFromType(eventType);

  @internal
  TStatus? previousStatusFromEvent<TEventSubType extends TEvent>(
          TEventSubType event) =>
      getContainer().previousStatusFromEvent(event);

  TStatus? statusOf<TEventSubType extends TEvent>([TEventSubType? event]) =>
      getContainer().statusOf(event);

  @internal
  TStatus? statusFromType(Type eventType) =>
      getContainer().statusFromType(eventType);

  @internal
  TStatus? statusFromEvent<TEventSubType extends TEvent>(TEventSubType event) =>
      getContainer().statusFromEvent(event);

  Stream<TStatus> streamStatusOf<TEventSubType extends TEvent>(
          [TEventSubType? event]) =>
      getContainer().streamStatusOf(event);

  @internal
  Stream<TStatus> streamStatusFromType(Type eventType) =>
      getContainer().streamStatusFromType(eventType);

  @internal
  Stream<TStatus> streamStatusFromEvent<TEventSubType extends TEvent>(
          TEventSubType event) =>
      getContainer().streamStatusFromEvent(event);

  Stream<PreviousCurrentStatusPair<TStatus>>
      streamStatusWithPreviousOf<TEventSubType extends TEvent>(
              [TEventSubType? event]) =>
          getContainer().streamStatusWithPreviousOf(event);

  @internal
  Stream<PreviousCurrentStatusPair<TStatus>> streamStatusWithPreviousFromType(
          Type eventType) =>
      getContainer().streamStatusWithPreviousFromType(eventType);

  @internal
  Stream<PreviousCurrentStatusPair<TStatus>>
      streamStatusWithPreviousFromEvent<TEventSubType extends TEvent>(
              TEventSubType event) =>
          getContainer().streamStatusWithPreviousFromEvent(event);

  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status, {
    bool allowMultipleInstances = false,
  }) =>
      getContainer().emitEventStatus(
        event,
        status,
        allowMultipleInstances: allowMultipleInstances,
      );

  @override
  @mustCallSuper
  // `super.close()` is called in the `BlocEventStatusContainer.close()`
  // method
  // ignore: must_call_super
  Future<void> close() async => getContainer().close();
}
