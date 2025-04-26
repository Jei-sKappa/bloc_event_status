import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// {@template multi_bloc_builder_with_custom_event_status}
/// A widget that listens to event statuses from a bloc and invokes a builder
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [TEvent]. When a new event of type [TEvent] is emitted by
/// the Bloc, the provided [builder] function is called with the current
/// `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// MultiBlocBuilderWithCustomEventStatus<SubjectBloc, SubjectEvent, SubjectState, MyStatus>(
///   // optionally filter the events to listen to
///   filter: (event) =>
///       (event is MySubjectEvent && event.subject == "Flutter") ||
///       (event is MyOtherSubjectEvent && event.otherSubject == "Dart"),
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
class MultiBlocBuilderWithCustomEventStatus<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TState,
    TStatus> extends StatelessWidget {
  /// {@macro multi_bloc_builder_with_custom_event_status}
  const MultiBlocBuilderWithCustomEventStatus({
    required this.builder,
    super.key,
    this.bloc,
    this.eventFilter,
    this.buildWhenState,
    this.buildWhenStatus,
  });

  /// {@macro multi_bloc_custom_event_status_listener.bloc}
  final TBloc? bloc;

  /// {@macro multi_bloc_custom_event_status_listener.filter}
  final BlocEventFilterBuilder<TEvent>? eventFilter;

  /// {@macro bloc_builder_with_custom_event_status.buildWhenState}
  final BlocBuilderCondition<TState>? buildWhenState;

  /// {@macro bloc_custom_event_status_builder.buildWhen}
  final BlocCustomEventStatusBuilderCondition<TStatus>? buildWhenStatus;

  /// {@template multi_bloc_builder_with_custom_event_status.builder}
  /// A function that renders the widget based on the current event, status and
  /// state.
  /// It takes the `context`, the `event` of type [TEvent], the
  /// `status` of type [TStatus] and `state` of type [TState] as parameters.
  ///
  /// The event can be null if no event is triggered yet.
  /// {@endtemplate}
  final BlocWidgetBuilderWithCustomEventStatus<TEvent, TStatus, TState> builder;

  @override
  Widget build(BuildContext context) {
    return MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, TStatus>(
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
