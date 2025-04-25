import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiBlocBuilderWithEventStatus<
    TBloc extends BlocEventStatusMixin<TEvent, TState>,
    TEvent,
    TState> extends StatelessWidget {
  final TBloc? bloc;

  final BlocCustomEventFilter<TEvent>? eventFilter;

  final BlocBuilderCondition<TState>? buildWhenState;

  final BlocCustomEventStatusBuilderCondition<TEvent, EventStatus>?
      buildWhenStatus;

  final BlocWidgetBuilderWithCustomEventStatus<TEvent, EventStatus,
      TState> builder;

  const MultiBlocBuilderWithEventStatus({
    super.key,
    required this.builder,
    this.bloc,
    this.eventFilter,
    this.buildWhenState,
    this.buildWhenStatus,
  });

  @override
  Widget build(BuildContext context) =>
      MultiBlocBuilderWithCustomEventStatus<TBloc, TEvent, TState, EventStatus>(
        bloc: bloc,
        eventFilter: eventFilter,
        buildWhenState: buildWhenState,
        buildWhenStatus: buildWhenStatus,
        builder: builder,
      );
}
