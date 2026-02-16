import 'package:flutter_bloc/flutter_bloc.dart';

class ProgrammedFailureCubit extends Cubit<bool> {
  ProgrammedFailureCubit() : super(false);

  void set(bool shouldFail) => emit(shouldFail);

  void forceFailure() => emit(true);

  void forceSuccess() => emit(false);

  // void randomlyFail() => emit(null);
}
