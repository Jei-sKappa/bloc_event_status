import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

mixin BlocCustomEventStatusMixin<TEvent, TState, TStatus>
    on Bloc<TEvent, TState> {
  // ignore_reason: The [BlocEventStatusContainer] is used to manage the event
  // status across Classes and Mixins
  // ignore: invalid_use_of_visible_for_testing_member
  BlocEventStatusContainer<TEvent, TState, TStatus>? _container;

  // ignore_reason: The [BlocEventStatusContainer] is used to manage the event
  // status across Classes and Mixins
  // ignore: invalid_use_of_visible_for_testing_member
  BlocEventStatusContainer<TEvent, TState, TStatus> _getContainer() =>
      _container ??= BlocEventStatusContainer(this);

  TStatus? statusOfAllEvents() => _getContainer().statusOfAllEvents();

  Stream<EventStatusUpdate<TEvent, TStatus>> streamAllEventStatus() =>
      _getContainer().streamStatusOfAllEvents();

  TStatus? statusOf<TEventSubType extends TEvent>() =>
      _getContainer().statusOf<TEventSubType>();

  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusOf<TEventSubType extends TEvent>() =>
          _getContainer().streamStatusOf<TEventSubType>();

  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status,
  ) =>
      _getContainer().emitEventStatus(
        event,
        status,
      );

  @override
  @mustCallSuper
  // `super.close()` is called in the `BlocEventStatusContainer.close()`
  // method
  // ignore: must_call_super
  Future<void> close() async => _getContainer().close();
}
