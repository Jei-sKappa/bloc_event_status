# BlocEventStatus

[![BlocEventStatus CI](https://github.com/Jei-sKappa/bloc_event_status/actions/workflows/bloc_event_status-test.yml/badge.svg)](https://github.com/Jei-sKappa/bloc_event_status/actions/workflows/bloc_event_status-test.yml)
[![codecov](https://codecov.io/github/Jei-sKappa/bloc_event_status/graph/badge.svg?token=LYNF1FJ8YF)](https://codecov.io/github/Jei-sKappa/bloc_event_status)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Compose event status tracking into your BLoC state — track loading, success, failure (or any custom status) per event type without modifying your main state logic.

## Packages

This repository is a monorepo containing the following packages:

| Package | Description | pub.dev |
|---|---|---|
| [bloc_event_status](./packages/bloc_event_status/) | Core library — `EventStatuses`, `EventStatusesMixin`, and the `@blocEventStatus` annotation. | [![pub package](https://img.shields.io/pub/v/bloc_event_status.svg)](https://pub.dev/packages/bloc_event_status) |
| [bloc_event_status_generator](./packages/bloc_event_status_generator/) | Code generator that produces `Emitter` extensions from `@blocEventStatus`-annotated Blocs. | [![pub package](https://img.shields.io/pub/v/bloc_event_status_generator.svg)](https://pub.dev/packages/bloc_event_status_generator) |

## Quick Start

```bash
# Core library
dart pub add bloc_event_status

# Optional: code generator for emitter extensions
dart pub add --dev bloc_event_status_generator build_runner
```

See the [bloc_event_status README](./packages/bloc_event_status/README.md) for full documentation and usage examples.

## Contributing

We welcome contributions! Please open an issue, submit a pull request or open a discussion on [GitHub](https://github.com/Jei-sKappa/bloc_event_status).

## License

This project is licensed under the [MIT License](./packages/bloc_event_status/LICENSE).
