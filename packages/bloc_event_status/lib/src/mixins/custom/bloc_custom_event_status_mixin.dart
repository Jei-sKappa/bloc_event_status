import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// A mixin that adds event status tracking capabilities to a Bloc.
///
/// Example:
/// ```dart
/// class SubjectBloc extends Bloc<SubjectEvent, SubjectState> with BlocCustomEventStatusMixin<SubjectEvent, SubjectState, MyStatus> {
///   // Your bloc implementation
/// }
/// ```
///
/// In order to emit an event status, you can use the `emitEventStatus` method:
/// ```dart
/// Future<void> _onMySubjectEvent(
///   MySubjectEvent event,
///   Emitter<SubjectState> emit,
/// ) async {
///   emitEventStatus(event, MyLoadingStatus());
///
///   try {
///     await loadSomething();
///   } catch (e) {
///     emitEventStatus(event, MyFailureStatus(e));
///     return;
///   }
///
///   // ... do something
///
///   emit(MyUpdatedSubjectState());
///
///   emitEventStatus(event, MySuccessStatus());
/// }
/// ```
///
/// You can also listen to the event status stream:
/// ```dart
/// final subscription = bloc.streamStatusOf<MySubjectEvent>().listen((update) {
///   // Handle the event status update
/// });
/// ```
///
/// Most of the time, you will want to use [BlocEventStatusListener] or
/// [BlocEventStatusBuilder] to listen to the event status updates in your
/// widget tree.
///
/// See also:
/// * [BlocEventStatusMixin], which comes with a default [TStatus] and some
///  convenience methods.
/// * [EventStatusUpdate], which represents a status update for an event
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

  /// {@macro bloc_event_status_container.status_of_all_events}
  TStatus? statusOfAllEvents() => _getContainer().statusOfAllEvents();

  /// {@macro bloc_event_status_container.stream_status_of_all_events}
  Stream<EventStatusUpdate<TEvent, TStatus>> streamAllEventStatus() =>
      _getContainer().streamStatusOfAllEvents();

  /// {@macro bloc_event_status_container.status_of}
  TStatus? statusOf<TEventSubType extends TEvent>() =>
      _getContainer().statusOf<TEventSubType>();

  /// {@macro bloc_event_status_container.stream_status_of}
  Stream<EventStatusUpdate<TEventSubType, TStatus>>
      streamStatusOf<TEventSubType extends TEvent>() =>
          _getContainer().streamStatusOf<TEventSubType>();

  /// {@macro bloc_event_status_container.emit_event_status}
  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    TStatus status,
  ) =>
      _getContainer().emitEventStatus(
        event,
        status,
      );

  /// {@macro bloc_event_status_container.close}
  @override
  @mustCallSuper
  // `super.close()` is called in the `BlocEventStatusContainer.close()`
  // method
  // ignore: must_call_super
  Future<void> close() async => _getContainer().close();
}
