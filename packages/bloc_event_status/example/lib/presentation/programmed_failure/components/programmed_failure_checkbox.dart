import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:example/presentation/programmed_failure/cubit/programmed_failure_cubit.dart';

class ProgrammedFailureCheckbox extends StatelessWidget {
  const ProgrammedFailureCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgrammedFailureCubit, bool>(
      builder: (context, shouldFail) {
        final statusText = switch (shouldFail) {
          true => 'enabled',
          false => 'disabled',
          // null => 'random',
        };
        return Row(
          children: [
            Text('Programmed Failure: $statusText'),
            Checkbox(
              // tristate: true,
              value: shouldFail,
              onChanged: (value) {
                context.read<ProgrammedFailureCubit>().set(value!);
              },
            ),
          ],
        );
      },
    );
  }
}
