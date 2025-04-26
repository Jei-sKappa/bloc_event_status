import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';

/// {@template bloc_event_status_builder}
/// A widget that listens to event statuses from a bloc and invokes a builder
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocEventStatusMixin] and listen
/// to events of type [TEventSubType]. When a new event of type [TEventSubType]
/// is emitted by the Bloc, the provided [builder] function is called with the
/// current `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// BlocEventStatusBuilder<SubjectBloc, SubjectEvent, MySubjectEvent, SubjectState>(
///   // optionally filter the events to listen to
///   filter: (event) => event.subject == 'Flutter',
///   // optionally select when the builder should be called
///   buildWhen: (previous, current) =>
///       previous != current &&
///       (previous is LoadingEventStatus || current is LoadingEventStatus),
///   // The builder function that will be called when a new status is emitted
///   builder: (context, event, status) {
///     if (status is LoadingEventStatus) {
///       return const CircularProgressIndicator();
///     }
///
///     return const Text('Flutter is awesome!');
///   },
///   bloc: subjectBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
class BlocEventStatusBuilder<TBloc extends BlocEventStatusMixin<TEvent, TState>,
    TEvent, TEventSubType extends TEvent, TState> extends StatelessWidget {
  /// {@macro bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@macro bloc_custom_event_status_listener.filter}
  final BlocEventFilterBuilder<TEventSubType>? filter;

  /// {@template bloc_event_status_builder.buildWhen}
  /// A function that determines when the `builder` should be called.
  /// It takes the previous and current status of type [EventStatus] and returns
  /// a boolean value.
  /// {@endtemplate}
  final BlocCustomEventStatusBuilderCondition<EventStatus>?
      buildWhen;

  /// {@template bloc_event_status_builder.builder}
  /// A function that renders the widget based on the current event and status.
  /// It takes the `context`, the `event` of type [TEventSubType], and the
  /// `status` of type [EventStatus] as parameters.
  ///
  /// The event can be null ony during the first build.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetBuilder<TEventSubType, EventStatus> builder;

  /// {@macro bloc_event_status_builder}
  const BlocEventStatusBuilder({
    super.key,
    required this.builder,
    this.bloc,
    this.filter,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) => BlocCustomEventStatusBuilder<TBloc,
          TEvent, TEventSubType, TState, EventStatus>(
        bloc: bloc,
        builder: builder,
        filter: filter,
        buildWhen: buildWhen,
      );
}
