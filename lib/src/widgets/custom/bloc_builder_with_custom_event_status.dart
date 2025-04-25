import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocWidgetBuilderWithCustomEventStatus<TEvent, TStatus, TState> = Widget
    Function(
  BuildContext context,
  TEvent? event,
  TStatus? status,
  TState state,
);

class BlocBuilderWithCustomEventStatus<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TState,
    TStatus> extends StatelessWidget {
  const BlocBuilderWithCustomEventStatus({
    required this.builder,
    super.key,
    this.bloc,
    this.event,
    this.eventFilter,
    this.buildWhenState,
    this.buildWhenStatus,
  });

  final TBloc? bloc;

  /// TODO: Add a description
  final TEventSubType? event;

  final BlocCustomEventFilter<TEventSubType>? eventFilter;

  final BlocBuilderCondition<TState>? buildWhenState;

  final BlocCustomEventStatusBuilderCondition<TEventSubType, TStatus>?
      buildWhenStatus;

  /// The event can be null if no event is triggered yet.
  final BlocWidgetBuilderWithCustomEventStatus<TEventSubType, TStatus, TState>
      builder;

  @override
  Widget build(BuildContext context) {
    return BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState,
        TStatus>(
      bloc: bloc,
      event: event,
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
