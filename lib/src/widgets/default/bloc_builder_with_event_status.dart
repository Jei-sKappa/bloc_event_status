import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocBuilderWithEventStatus<
    TBloc extends BlocEventStatusMixin<TEvent, TState>,
    TEvent,
    TEventSubType extends TEvent,
    TState> extends StatelessWidget {
  final TBloc? bloc;

  final BlocCustomEventFilter<TEventSubType>? eventFilter;

  final BlocBuilderCondition<TState>? buildWhenState;

  final BlocCustomEventStatusBuilderCondition<TEventSubType, EventStatus>?
      buildWhenStatus;

  final BlocWidgetBuilderWithCustomEventStatus<TEventSubType, EventStatus,
      TState> builder;

  const BlocBuilderWithEventStatus({
    super.key,
    required this.builder,
    this.bloc,
    this.eventFilter,
    this.buildWhenState,
    this.buildWhenStatus,
  });

  @override
  Widget build(BuildContext context) => BlocBuilderWithCustomEventStatus<TBloc,
          TEvent, TEventSubType, TState, EventStatus>(
        bloc: bloc,
        eventFilter: eventFilter,
        buildWhenState: buildWhenState,
        buildWhenStatus: buildWhenStatus,
        builder: builder,
      );
}
