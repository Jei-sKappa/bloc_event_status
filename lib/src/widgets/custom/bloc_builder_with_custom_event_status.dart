import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocWidgetBuilderWithCustomEventStatus<TState, TStatus> = Widget Function(
  BuildContext context,
  TState state,
  TStatus? status,
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
    this.buildWhenState,
    this.buildWhenStatus,
  });

  final TBloc? bloc;

  /// TODO: Add a description
  final TEventSubType? event;

  final BlocBuilderCondition<TState>? buildWhenState;

  final BlocCustomEventStatusBuilderCondition<TStatus>? buildWhenStatus;

  final BlocWidgetBuilderWithCustomEventStatus<TState, TStatus> builder;

  @override
  Widget build(BuildContext context) {
    return BlocCustomEventStatusBuilder<TBloc, TEvent, TEventSubType, TState, TStatus>(
      bloc: bloc,
      event: event,
      buildWhen: buildWhenStatus,
      builder: (context, status) {
        return BlocBuilder<TBloc, TState>(
          bloc: bloc,
          buildWhen: buildWhenState,
          builder: (context, state) {
            return builder(context, state, status);
          },
        );
      },
    );
  }
}
