import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:example/app/app.dart';

final talker = Talker();

void main() {
  Bloc.observer = TalkerBlocObserver(
    talker: talker,
    settings: const TalkerBlocLoggerSettings(
      // printChanges: true,
      // printTransitions: false,
      printStateFullData: false,
    ),
  );

  runApp(const TodoApp());
}
