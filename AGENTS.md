# AGENTS.md

This file provides guidance to AI Agents when working with code in this repository.
Remember to update this file when you make significant changes that needs to be remembered across session.

## Project Overview

`bloc_event_status` is a Dart/Flutter package that enables event status tracking in BLoC state management without modifying the main state. Published on pub.dev at version 2.0.0.

## Repository Structure

Monorepo with a single package:
- `packages/bloc_event_status/` — main library package
  - `lib/src/event_statuses.dart` — core `EventStatuses<TEvent, TStatus>` immutable class
  - `lib/src/event_statuses_mixin.dart` — `EventStatusesMixin` convenience accessor mixin
  - `test/` — unit tests (Dart `test` package)
  - `example/` — Flutter example app demonstrating real-world usage

## Flutter Version

Uses FVM (Flutter Version Manager). Flutter version is `3.38.6` (configured in `.fvmrc`). Use `fvm flutter` or set Flutter SDK path to `.fvm/versions/3.38.6`.

## Commands

All commands run from `packages/bloc_event_status/`:

```bash
# Install dependencies
fvm flutter pub get

# Run tests
fvm flutter test
fvm flutter test --coverage

# Lint / analyze
fvm flutter analyze

# Format
fvm dart format .
```

For the example app, run from `packages/bloc_event_status/example/`:
```bash
fvm flutter pub get
fvm flutter run -d macos
# Regenerate freezed models:
fvm dart run build_runner build --delete-conflicting-outputs
```

## API Reference

### `EventStatuses<TEvent, TStatus>`

Immutable class (extends `Equatable`) that stores the status of each event type.

| Member | Description |
|---|---|
| `const EventStatuses()` | Creates an empty instance (use as initial value). |
| `update<TEventSubType>(event, status)` | Returns a **new** `EventStatuses` with the entry for `TEventSubType` updated. |
| `statusOf<TEventSubType>()` | Returns the current `TStatus` for `TEventSubType`, or `null`. |
| `eventOf<TEventSubType>()` | Returns the last `TEventSubType` instance that was updated, or `null`. |
| `eventStatusOf<TEventSubType>()` | Returns the full `EventStatusUpdate` record `({event, status})` for `TEventSubType`, or `null`. |
| `lastEventStatus` | Returns the most recently updated `EventStatusUpdate`, regardless of event type. |

### `EventStatusesMixin<TEvent, TStatus>`

Optional mixin for your BLoC state. Requires you to implement `EventStatuses<TEvent, TStatus> get eventStatuses`. Delegates all four query methods (`statusOf`, `eventOf`, `eventStatusOf`, `lastEventStatus`) to `eventStatuses`, so you can call them directly on the state.

### `EventStatusUpdate<TEvent, TStatus>`

A record typedef: `({TEvent event, TStatus status})`. Returned by `eventStatusOf` and `lastEventStatus`.

## Example app

### Pattern used

- BLoC state extends `Equatable` and uses `EventStatusesMixin`
- Emitter extension or manual `emit(state.copyWith(...))` propagates status updates
- UI uses `BlocListener`, `BlocSelector`, or `BlocBuilder` to react to specific event statuses

## Commit Scopes

Conventional commits with scopes: `bes` (bloc_event_status package), `example` (example app).
