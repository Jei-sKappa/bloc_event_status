import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for the `builder` function which takes the [context] along with
/// the [event], [status] and [state] as parameters.
///
/// It is called whenever the [BlocBuilderWithCustomEventStatus] receives
/// an event that matches the `filter` and the `listenWhen` condition specified.
typedef BlocWidgetBuilderWithCustomEventStatus<TEvent, TStatus, TState> = Widget
    Function(
  BuildContext context,
  TEvent? event,
  TStatus? status,
  TState state,
);

/// {@template bloc_builder_with_custom_event_status}
/// A widget that listens to event statuses from a bloc and invokes a builder
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [TEventSubType]. When a new event of type [TEventSubType]
/// is emitted by the Bloc, the provided [builder] function is called with the
/// current `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// BlocBuilderWithCustomEventStatus<SubjectBloc, SubjectEvent, MySubjectEvent, SubjectState, MyStatus>(
///   // optionally filter the events to listen to
///   filter: (event) => event.subject == 'Flutter',
///   // optionally select when the builder should be called
///   buildWhenStatus: (previous, current) =>
///       previous != current &&
///       (previous is MyLoadingStatus || current is MyLoadingStatus),
///   // optionally select when the builder should be called
///   buildWhenState: (previous, current) =>
///       previous != current &&
///       (previous.subject == "React Native" || current.subject == "Flutter"),
///   // The builder function that will be called when a new status is emitted
///   builder: (context, event, status, state) {
///     if (status is MyLoadingStatus) {
///       return const CircularProgressIndicator();
///     }
///
///     return const Text('Flutter is awesome! Here is the state: $state');
///   },
///   bloc: subjectBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
class BlocBuilderWithCustomEventStatus<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TState,
    TStatus> extends StatelessWidget {
  /// {@macro bloc_builder_with_custom_event_status}
  const BlocBuilderWithCustomEventStatus({
    required this.builder,
    super.key,
    this.bloc,
    this.eventFilter,
    this.buildWhenState,
    this.buildWhenStatus,
  });

  /// {@macro bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@macro bloc_custom_event_status_listener.filter}
  final BlocEventFilterBuilder<TEventSubType>? eventFilter;

  /// {@template bloc_builder_with_custom_event_status.buildWhenState}
  /// A function that determines when the `builder` should be called.
  /// It takes the previous and current status of type [TState] and returns a
  /// boolean value.
  /// {@endtemplate}
  final BlocBuilderCondition<TState>? buildWhenState;

  /// {@macro bloc_custom_event_status_builder.buildWhen}
  final BlocCustomEventStatusBuilderCondition<TStatus>?
      buildWhenStatus;

  /// {@template bloc_builder_with_custom_event_status.builder}
  /// A function that renders the widget based on the current event, status and
  /// state.
  /// It takes the `context`, the `event` of type [TEventSubType], the
  /// `status` of type [TStatus] and `state` of type [TState] as parameters.
  ///
  /// The event can be null if no event is triggered yet.
  /// {@endtemplate}
  final BlocWidgetBuilderWithCustomEventStatus<TEventSubType, TStatus, TState>
      builder;

  @override
  Widget build(BuildContext context) {
    return BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState,
        TStatus>(
      bloc: bloc,
      filter: eventFilter,
      buildWhen: buildWhenStatus,
      builder: (context, event, status) {
        return BlocBuilder<TBloc, TState>(
          bloc: bloc,
          buildWhen: buildWhenState,
          builder: (context, state) {
            return builder(context, event, status, state);
          },
        );
      },
    );
  }
}
