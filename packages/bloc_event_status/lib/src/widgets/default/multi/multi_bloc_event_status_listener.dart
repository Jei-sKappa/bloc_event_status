import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

/// {@template multi_bloc_event_status_listener}
/// A widget that listens to event statuses from a bloc and invokes a listener
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocEventStatusMixin] and listen
/// to events of type [TEvent]. When a new event of type [TEvent] is emitted by
/// the Bloc, the provided [listener] function is called with the current
/// `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// MultiBlocEventStatusListener<SubjectBloc, SubjectEvent>(
///   // optionally filter the events to listen to
///   filter: (event) =>
///       (event is MySubjectEvent && event.subject == "Flutter") ||
///       (event is MyOtherSubjectEvent && event.otherSubject == "Dart"),
///   // optionally select when the listener should be called
///   listenWhen: (previous, current) => previous != current && current is FailureEventStatus,
///   // The listener function that will be called when a new status is emitted
///   listener: (context, event, status) {
///     print('Oops! Something went wrong with the Flutter subject: ${event.error}');
///   },
///   bloc: subjectBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
class MultiBlocEventStatusListener<
    TBloc extends BlocEventStatusMixin<TEvent, dynamic>,
    TEvent> extends SingleChildStatelessWidget {
  /// {@macro multi_bloc_event_status_listener}
  const MultiBlocEventStatusListener({
    required this.listener,
    super.key,
    this.bloc,
    this.filter,
    this.listenWhen,
    super.child,
  });

  /// {@macro multi_bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@template multi_bloc_custom_event_status_listener.listener}
  /// A function that defines the action to be taken when a new event status is
  /// emitted.
  /// It takes the `context`, the `event` of type [TEvent], and the
  /// `status` of type [EventStatus] as parameters.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetListener<TEvent, EventStatus> listener;

  /// {@macro multi_bloc_custom_event_status_listener.filter}
  final BlocEventFilterListener<TEvent>? filter;

  /// {@macro bloc_event_status_listener.listenWhen}
  final BlocCustomEventStatusListenerCondition<EventStatus>? listenWhen;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) =>
      MultiBlocCustomEventStatusListener<TBloc, TEvent, EventStatus>(
        bloc: bloc,
        listener: listener,
        filter: filter,
        listenWhen: listenWhen,
        child: child,
      );
}
