import 'dart:async';

import 'package:bloc_event_status/bloc_event_status.dart';
import 'package:bloc_event_status/helpers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

/// {@template multi_bloc_custom_event_status_listener}
/// A widget that listens to event statuses from a bloc and invokes a listener
/// function in response to new statuses.
///
/// This widget is used to interact with [BlocCustomEventStatusMixin] and listen
/// to events of type [TEvent]. When a new event of type [TEvent] is emitted by
/// the Bloc, the provided [listener] function is called with the current
/// `context`, the `event` itself, and the current `status`.
///
/// Example:
/// ```dart
/// MultiBlocCustomEventStatusListener<SubjectBloc, SubjectEvent, MyStatus>(
///   // optionally filter the events to listen to
///   filter: (event) =>
///       (event is MySubjectEvent && event.subject == "Flutter") ||
///       (event is MyOtherSubjectEvent && event.otherSubject == "Dart"),
///   // optionally select when the listener should be called
///   listenWhen: (previous, current) => previous != current && current is MyFailureStatus,
///   // The listener function that will be called when a new status is emitted
///   listener: (context, event, status) {
///     print('Oops! Something went wrong with the Flutter subject: ${event.error}');
///   },
///   bloc: subjectBloc, // You don't have to pass it if you provided it in context
///   child: SomeWidget(),
/// )
/// ```
/// {@endtemplate}
class MultiBlocCustomEventStatusListener<
    TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
    TEvent,
    TStatus> extends SingleChildStatefulWidget {
  /// {@macro multi_bloc_custom_event_status_listener}
  const MultiBlocCustomEventStatusListener({
    required this.listener,
    super.key,
    this.bloc,
    this.filter,
    this.listenWhen,
    super.child,
  });

  /// {@template multi_bloc_custom_event_status_listener.bloc}
  /// The Bloc from which to listen to events of type [TEvent]. If not
  /// provided, the nearest ancestor Bloc of type [TBloc] in the widget tree
  /// will be used.
  /// {@endtemplate}
  final TBloc? bloc;

  /// {@template multi_bloc_custom_event_status_listener.listener}
  /// A function that defines the action to be taken when a new event status is
  /// emitted.
  /// It takes the `context`, the `event` of type [TEvent], and the
  /// `status` of type [TStatus] as parameters.
  /// {@endtemplate}
  final BlocCustomEventStatusWidgetListener<TEvent, TStatus> listener;

  /// {@template multi_bloc_custom_event_status_listener.filter}
  /// A function that filters the events to listen to.
  /// It takes an event of type [TEvent] and returns a boolean value.
  /// {@endtemplate}
  final BlocEventFilterListener<TEvent>? filter;

  /// {@macro bloc_custom_event_status_listener.listenWhen}
  final BlocCustomEventStatusListenerCondition<TStatus>? listenWhen;

  @override
  SingleChildState<MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus>>
      createState() =>
          _BloCustomcEventStatusListenerBaseState<TBloc, TEvent, TStatus>();
}

class _BloCustomcEventStatusListenerBaseState<
        TBloc extends BlocCustomEventStatusMixin<TEvent, dynamic, TStatus>,
        TEvent,
        TStatus>
    extends SingleChildState<
        MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus>> {
  final Map<
          Type,
          StreamSubscription<
              PreviousValuePair<EventStatusUpdate<TEvent, TStatus>>>>
      _streamSubscriptionMap = {};

  StreamSubscription<PreviousValuePair<EventStatusUpdate<TEvent, TStatus>>>?
      _allEventsStreamSubscription;

  late TBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = widget.bloc ?? context.read<TBloc>();

    _subscribe();
  }

  @override
  void didUpdateWidget(
    MultiBlocCustomEventStatusListener<TBloc, TEvent, TStatus> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldBloc = oldWidget.bloc ?? context.read<TBloc>();
    final currentBloc = widget.bloc ?? oldBloc;

    if (oldBloc != currentBloc) {
      if (_streamSubscriptionMap.isNotEmpty ||
          _allEventsStreamSubscription != null) {
        _unsubscribe();
        _bloc = currentBloc;
      }

      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bloc = widget.bloc ?? context.read<TBloc>();

    if (_bloc != bloc) {
      if (_streamSubscriptionMap.isNotEmpty ||
          _allEventsStreamSubscription != null) {
        _unsubscribe();
        _bloc = bloc;
      }

      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return child ?? const SizedBox();
  }

  @override
  void dispose() {
    _unsubscribe();

    super.dispose();
  }

  void _subscribe() {
    _allEventsStreamSubscription = _bloc
        .streamAllEventStatus()
        .where((update) => widget.filter?.call(update.event) ?? true)
        .transform(WithPrevious())
        .listen(
      (data) {
        if (!mounted) return;

        final update = data.current;
        final event = update.event;
        final currentStatus = update.status;
        final previousStatus = data.previous?.status;

        final shouldTrigger =
            widget.listenWhen?.call(previousStatus, currentStatus) ?? true;
        if (shouldTrigger) {
          widget.listener(context, event, currentStatus);
        }
      },
    );
  }

  void _unsubscribe() {
    _allEventsStreamSubscription?.cancel();
    for (final streamSubscription in _streamSubscriptionMap.values) {
      streamSubscription.cancel();
    }
    _streamSubscriptionMap.clear();
  }
}
