import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

/// A mixin that adds event status tracking capabilities to a Bloc.
///
/// Example:
/// ```dart
/// class SubjectBloc extends Bloc<SubjectEvent, SubjectState> with BlocEventStatusMixin<SubjectEvent, SubjectState> {
///   // Your bloc implementation
/// }
/// ```
///
/// In order to emit an event status, you can use custom methods provided by
/// this mixin:
/// ```dart
/// Future<void> _onMySubjectEvent(
///   MySubjectEvent event,
///   Emitter<SubjectState> emit,
/// ) async {
///   emitLoadingStatus(event); // equivalent to emitEventStatus(event, LoadingEventStatus());
///
///   try {
///     await loadSomething();
///   } catch (e) {
///     emitFailureStatus(event, error: e); // equivalent to emitEventStatus(event, FailureEventStatus(e));
///     return;
///   }
///
///   // ... do something
///
///   emit(MyUpdatedSubjectState());
///
///   emitSuccessStatus(event); // equivalent to emitEventStatus(event, SuccessEventStatus());
/// }
/// ```
///
/// The biggest advantage of using this mixin instead of
/// [BlocCustomEventStatusMixin] is that you have access to [handleEventStatus]
/// method, which allows you to wrap your event handlers with it and
/// automatically emit the loading, success, and failure statuses for you.
///
/// See the example below:
/// ```dart
/// class SubjectBloc extends Bloc<SubjectEvent, SubjectState> with BlocEventStatusMixin<SubjectEvent, SubjectState> {
///   SubjectBloc() : super(const SubjectState.initial()) {
///     on<MySubjectEvent>(handleEventStatus(_onMySubjectEvent));
///   }
///
///   Future<void> _onMySubjectEvent(
///     MySubjectEvent event,
///     Emitter<SubjectState> emit,
///   ) async {
///     await loadSomething();
///
///     // ... do something
///
///     emit(MyUpdatedSubjectState());
///   }
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
/// * [BlocCustomEventStatusMixin], which enalbes you to use a custom status
/// type instead of the default [EventStatus].
/// * [EventStatusUpdate], which represents a status update for an event
mixin BlocEventStatusMixin<TEvent, TState> on Bloc<TEvent, TState>
    implements BlocCustomEventStatusMixin<TEvent, TState, EventStatus> {
  // ignore_reason: [BlocEventStatusContainer] is used to manage the event
  // status across Classes and Mixins
  // ignore: invalid_use_of_visible_for_testing_member
  BlocEventStatusContainer<TEvent, TState, EventStatus>? _container;

  // ignore_reason: The [BlocEventStatusContainer] is used to manage the event
  // status across Classes and Mixins
  // ignore: invalid_use_of_visible_for_testing_member
  BlocEventStatusContainer<TEvent, TState, EventStatus> _getContainer() =>
      _container ??= BlocEventStatusContainer();

  /// {@macro bloc_event_status_container.status_of_all_events}
  @override
  EventStatus? statusOfAllEvents() => _getContainer().statusOfAllEvents();

  /// {@macro bloc_event_status_container.stream_status_of_all_events}
  @override
  Stream<EventStatusUpdate<TEvent, EventStatus>> streamStatusOfAllEvents() =>
      _getContainer().streamStatusOfAllEvents();

  /// {@macro bloc_event_status_container.status_of}
  @override
  EventStatus? statusOf<TEventSubType extends TEvent>() =>
      _getContainer().statusOf<TEventSubType>();

  /// {@macro bloc_event_status_container.stream_status_of}
  @override
  Stream<EventStatusUpdate<TEventSubType, EventStatus>>
      streamStatusOf<TEventSubType extends TEvent>() =>
          _getContainer().streamStatusOf<TEventSubType>();

  /// {@macro bloc_event_status_container.emit_event_status}
  @override
  @protected
  void emitEventStatus<TEventSubType extends TEvent>(
    TEventSubType event,
    EventStatus status,
  ) =>
      _getContainer().emitEventStatus(
        event,
        status,
      );

  /// Emits a loading status for the given [event].
  ///
  /// This method is a convenience wrapper around [emitEventStatus] that
  /// automatically creates a [LoadingEventStatus] instance.
  ///
  /// Usage:
  /// ```dart
  /// emitLoadingStatus(event); // equivalent to emitEventStatus(event, LoadingEventStatus());
  /// ```
  @protected
  void emitLoadingStatus<TEventSubType extends TEvent>(TEventSubType event) =>
      _getContainer().emitEventStatus(event, const LoadingEventStatus());

  /// Emits a failure status for the given [event] and optionally adds the
  /// [error] to the bloc.
  ///
  /// This method is a convenience wrapper around [emitEventStatus] that
  /// automatically creates a [FailureEventStatus] instance.
  ///
  ///
  /// The [error] parameter is optional and can be used to provide additional
  /// information about the failure.
  ///
  /// If [addError] is set to `true`, the error will be added to the bloc using
  /// `addError`.
  ///
  /// Usage:
  /// ```dart
  /// emitFailureStatus(event, error: e); // equivalent to emitEventStatus(event, FailureEventStatus(e));
  /// ```
  @protected
  void emitFailureStatus<TEventSubType extends TEvent,
      TFailure extends Exception>(
    TEventSubType event, {
    TFailure? error,
    bool addError = true,
  }) {
    _getContainer().emitEventStatus(event, FailureEventStatus(error));
    if (addError && error != null) {
      this.addError(error, StackTrace.current);
    }
  }

  /// Emits a success status for the given [event].
  ///
  /// This method is a convenience wrapper around [emitEventStatus] that
  /// automatically creates a [SuccessEventStatus] instance.
  ///
  /// The [data] parameter is optional and can be used to provide additional
  /// information about the success.
  ///
  /// Usage:
  /// ```dart
  /// emitSuccessStatus(event); // equivalent to emitEventStatus(event, SuccessEventStatus());
  /// ```
  @protected
  void emitSuccessStatus<TEventSubType extends TEvent, TData extends dynamic>(
    TEventSubType event, {
    TData? data,
  }) =>
      _getContainer().emitEventStatus(event, SuccessEventStatus(data));

  /// Wrapper function for event handlers that automatically emits loading,
  /// success, and failure statuses.
  ///
  /// This method also automatically handles the try-catch block for you, so you
  /// don't have to; it will catch any object of type [TFailure] throwed by the
  /// event handler and add them to the bloc's error stream using `addError`.
  ///
  /// Usage:
  /// ```dart
  /// class SubjectBloc extends Bloc<SubjectEvent, SubjectState> with BlocEventStatusMixin<SubjectEvent, SubjectState> {
  ///   SubjectBloc() : super(const SubjectState.initial()) {
  ///     on<MySubjectEvent>(handleEventStatus(_onMySubjectEvent));
  ///   }
  ///
  ///   Future<void> _onMySubjectEvent(
  ///     MySubjectEvent event,
  ///     Emitter<SubjectState> emit,
  ///   ) async {
  ///     // No need to call emitLoadingStatus(event) here
  ///
  ///     // No need to wrap the event handler with try-catch
  ///     await loadSomething();
  ///
  ///     emit(MyUpdatedSubjectState());
  ///
  ///     // No need to call emitSuccessStatus(event) here
  ///   }
  /// }
  /// ```
  EventHandler<TEventSubType, TState> handleEventStatus<
          TEventSubType extends TEvent, TFailure extends Exception>(
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
            emitSuccessStatus<TEventSubType, Null>(event);
          }
        } on TFailure catch (e) {
          if (emitFailure) {
            emitFailureStatus(event, error: e);
          }
          addError(e, StackTrace.current);
        }
      };

  /// {@macro BlocEventStatusContainer.close}
  @override
  @mustCallSuper
  Future<void> close() async {
    await _getContainer().close();
    await super.close();
  }
}
