import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

mixin BlocCustomEventStatusMixin<TEvent, TState, TStatus>
    on Bloc<TEvent, TState> {
  BlocEventStatusContainer<TEvent, TState, TStatus>? _container;

  BlocEventStatusContainer<TEvent, TState, TStatus> getContainer() =>
      _container ??= BlocEventStatusContainer(this);

  TStatus? statusOfAllEvents() => getContainer().statusOfAllEvents();

  Stream<EventStatusUpdate<TEvent, TStatus>> streamAllEventStatus() =>
      getContainer().streamStatusOfAllEvents();

  TStatus? statusOf<TEventSubType extends TEvent>() =>
      getContainer().statusOf<TEventSubType>();

  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusOf<TEventSubType extends TEvent>() =>
          getContainer().streamStatusOf<TEventSubType>();

  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status,
  ) =>
      getContainer().emitEventStatus(
        event,
        status,
      );

  @override
  @mustCallSuper
  // `super.close()` is called in the `BlocEventStatusContainer.close()`
  // method
  // ignore: must_call_super
  Future<void> close() async => getContainer().close();
}
