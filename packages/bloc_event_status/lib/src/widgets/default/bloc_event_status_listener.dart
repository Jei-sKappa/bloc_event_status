import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

/// {@template bloc_event_status_listener}
/// A widget that listens to event statuses from a bloc and invokes a listener
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocEventStatusMixin] and listen
/// to events of type [TEventSubType]. When a new event of type [TEventSubType]
/// is emitted by the Bloc, the provided [listener] function is called with the
/// current `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// BlocEventStatusListener<SubjectBloc, SubjectEvent, MySubjectEvent>(
///   // optionally filter the events to listen to
///   filter: (event) => event.subject == 'Flutter',
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
class BlocEventStatusListener<
    TBloc extends BlocEventStatusMixin<TEvent, dynamic>,
    TEvent,
    TEventSubType extends TEvent> extends SingleChildStatelessWidget {
  /// {@macro bloc_event_status_listener}
  const BlocEventStatusListener({
    required this.listener,
    super.key,
    this.bloc,
    this.filter,
    this.listenWhen,
    super.child,
  });

  /// {@macro bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@template bloc_event_status_listener.listener}
  /// A function that defines the action to be taken when a new event status is
  /// emitted.
  /// It takes the `context`, the `event` of type [TEventSubType], and the
  /// `status` of type [EventStatus] as parameters.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetListener<TEventSubType, EventStatus>
      listener;

  /// {@macro bloc_custom_event_status_listener.filter}
  final BlocEventFilterListener<TEventSubType>? filter;

  /// {@template bloc_event_status_listener.listenWhen}
  /// A function that determines when the `listener` should be called.
  /// It takes the previous and current status of type [EventStatus] and returns a
  /// boolean value.
  /// {@endtemplate}
  final BlocCustomEventStatusListenerCondition<EventStatus>? listenWhen;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) =>
      BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, EventStatus>(
        bloc: bloc,
        listener: listener,
        filter: filter,
        listenWhen: listenWhen,
        child: child,
      );
}
