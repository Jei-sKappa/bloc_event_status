import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';

/// {@template multi_bloc_event_status_builder}
/// A widget that listens to event statuses from a bloc and invokes a builder
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocEventStatusMixin] and listen
/// to events of type [TEvent]. When a new event of type [TEvent] is emitted by
/// the Bloc, the provided [builder] function is called with the current
/// `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// MultiBlocEventStatusBuilder<SubjectBloc, SubjectEvent, SubjectState>(
///   // optionally filter the events to listen to
///   filter: (event) =>
///       (event is MySubjectEvent && event.subject == "Flutter") ||
///       (event is MyOtherSubjectEvent && event.otherSubject == "Dart"),
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
class MultiBlocEventStatusBuilder<
    TBloc extends BlocEventStatusMixin<TEvent, TState>,
    TEvent,
    TState> extends StatelessWidget {
  /// {@macro multi_bloc_event_status_builder}
  const MultiBlocEventStatusBuilder({
    required this.builder,
    super.key,
    this.bloc,
    this.filter,
    this.buildWhen,
  });

  /// {@macro multi_bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@macro multi_bloc_custom_event_status_listener.filter}
  final BlocEventFilterBuilder<TEvent>? filter;

  /// {@macro bloc_event_status_builder.buildWhen}
  final BlocCustomEventStatusBuilderCondition<EventStatus>? buildWhen;

  /// {@template multi_bloc_event_status_builder.builder}
  /// A function that renders the widget based on the current event and status.
  /// It takes the `context`, the `event` of type [TEvent], and the `status` of
  /// type [EventStatus] as parameters.
  ///
  /// The event can be null ony during the first build.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetBuilder<TEvent, EventStatus> builder;

  @override
  Widget build(BuildContext context) =>
      MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, EventStatus>(
        bloc: bloc,
        builder: builder,
        filter: filter,
        buildWhen: buildWhen,
      );
}
