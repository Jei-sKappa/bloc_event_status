import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiBlocBuilderWithCustomEventStatus<
    TBloc extends BlocCustomEventStatusMixin<TEvent, TState, TStatus>,
    TEvent,
    TState,
    TStatus> extends StatelessWidget {
  const MultiBlocBuilderWithCustomEventStatus({
    required this.builder,
    super.key,
    this.bloc,
    this.eventFilter,
    this.buildWhenState,
    this.buildWhenStatus,
  });

  final TBloc? bloc;

  final BlocCustomEventFilter<TEvent>? eventFilter;

  final BlocBuilderCondition<TState>? buildWhenState;

  final BlocCustomEventStatusBuilderCondition<TEvent, TStatus>? buildWhenStatus;

  /// The event can be null if no event is triggered yet.
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
