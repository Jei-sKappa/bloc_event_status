import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';

class MultiBlocEventStatusBuilder<
    TBloc extends BlocEventStatusMixin<TEvent, TState>,
    TEvent,
    TState> extends StatelessWidget {
  /// The [bloc] that the [BlocCustomEventStatusBuilder] will interact with.
  /// If omitted, [BlocCustomEventStatusBuilder] will automatically perform a lookup using
  /// [BlocProvider] and the current `BuildContext`.
  final TBloc? bloc;

  final BlocCustomEventFilter<TEvent>? filter;

  /// {@macro bloc_builder_build_when}
  final BlocCustomEventStatusBuilderCondition<TEvent, EventStatus>? buildWhen;

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final BlocCustomEventStatusWidgetBuilder<TEvent, EventStatus> builder;

  const MultiBlocEventStatusBuilder({
    super.key,
    required this.builder,
    this.bloc,
    this.filter,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) =>
      MultiBlocCustomEventStatusBuilder<TBloc, TEvent, TState, EventStatus>(
        bloc: bloc,
        builder: builder,
        filter: filter,
        buildWhen: buildWhen,
      );
}
