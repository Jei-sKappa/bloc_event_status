import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:flutter/widgets.dart';
import 'package:nested/nested.dart';

class BlocEventStatusListener<
    TBloc extends BlocEventStatusMixin<TEvent, dynamic>,
    TEvent,
    TEventSubType extends TEvent> extends SingleChildStatelessWidget {
  /// The Bloc from which to listen to events of type [P]. If not provided,
  /// the nearest ancestor Bloc of type [TBloc] in the widget tree will be used.
  final TBloc? bloc;

  /// TODO: Add a description
  final TEventSubType? event;

  /// A function that defines the behavior when a new event of type [P] is
  /// emitted by the Bloc. It takes the current [BuildContext] and the
  /// event itself as parameters and is responsible for handling the event.
  final BlocCustomEventStatusWidgetListener<TEventSubType, EventStatus>
      listener;

  final BlocCustomEventStatusListenerCondition<TEventSubType, EventStatus>?
      listenWhen;

  const BlocEventStatusListener({
    super.key,
    required this.listener,
    this.bloc,
    this.event,
    this.listenWhen,
    super.child,
  });

  @override
  Widget buildWithChild(BuildContext context, Widget? child) =>
      BlocCustomEventStatusListener<TBloc, TEvent, TEventSubType, EventStatus>(
        bloc: bloc,
        event: event,
        listener: listener,
        listenWhen: listenWhen,
        child: child,
      );
}
