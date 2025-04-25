import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';

class BlocEventStatusBuilder<TBloc extends BlocEventStatusMixin<TEvent, TState>,
    TEvent, TEventSubType extends TEvent, TState> extends StatelessWidget {
  /// The [bloc] that the [BlocCustomEventStatusBuilder] will interact with.
  /// If omitted, [BlocCustomEventStatusBuilder] will automatically perform a lookup using
  /// [BlocProvider] and the current `BuildContext`.
  final TBloc? bloc;

  /// TODO: Add a description
  final TEventSubType? event;

  /// {@macro bloc_builder_build_when}
  final BlocCustomEventStatusBuilderCondition<TEventSubType, EventStatus>?
      buildWhen;

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final BlocCustomEventStatusWidgetBuilder<TEventSubType, EventStatus> builder;

  const BlocEventStatusBuilder({
    super.key,
    required this.builder,
    this.bloc,
    this.event,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) => BlocCustomEventStatusBuilder<TBloc,
          TEvent, TEventSubType, TState, EventStatus>(
        bloc: bloc,
        event: event,
        builder: builder,
        buildWhen: buildWhen,
      );
}
