import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_event_status_builder.dart';
import 'bloc_event_status_mixin.dart';

typedef BlocWidgetBuilderWithEventStatus<TState, TStatus> = Widget Function(
  BuildContext context,
  TState state,
  TStatus? status,
);

class BlocBuilderWithEventStatus<
    TBloc extends BlocEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TEventSubType extends TEvent,
    TState,
    TStatus> extends StatelessWidget {
  const BlocBuilderWithEventStatus({
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

  final BlocEventStatusBuilderCondition<TStatus>? buildWhenStatus;

  final BlocWidgetBuilderWithEventStatus<TState, TStatus> builder;

  @override
  Widget build(BuildContext context) {
    return BlocEventStatusBuilder<TBloc, TEvent, TEventSubType, TStatus>(
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
