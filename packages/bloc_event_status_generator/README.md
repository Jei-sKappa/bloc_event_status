# bloc_event_status_generator

Code generator for [bloc_event_status](https://pub.dev/packages/bloc_event_status) emitter extensions.

## Usage

1. Add dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  bloc_event_status: ^2.0.0

dev_dependencies:
  bloc_event_status_generator: ^1.0.0
  build_runner: ^2.0.0
```

2. Annotate your Bloc class:

```dart
import 'package:bloc_event_status/bloc_event_status.dart';

part 'my_bloc.bes.g.dart';

@blocEventStatus
class MyBloc extends Bloc<MyEvent, MyState> {
  // ...
}
```

3. Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## VS Code tip

To keep generated `*.g.dart` files nested under their source file in the Explorer, add this to your `.vscode/settings.json`:

```json
{
  "explorer.fileNesting.patterns": {
    "*.dart": "${capture}*.g.dart"
  }
}
```
