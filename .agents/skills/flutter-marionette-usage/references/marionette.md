# Marionette MCP

Marionette is a LeanCode MCP server that lets an AI agent interact with a **running Flutter app at runtime** — inspect the widget tree, tap elements, enter text, scroll, take screenshots, read logs, and trigger hot reload.

Think of it as "Playwright for Flutter, for AI agents."

## Marionette vs Patrol

Both are LeanCode testing tools, but they solve different problems:

| | Marionette | Patrol |
|---|---|---|
| Purpose | Runtime exploration, smoke verification | Deterministic E2E test suites |
| Runs against | A live `flutter run` debug session | `patrol develop` or `patrol test` runner |
| Test files | None — agent drives the app interactively | Dart test files in `patrol_test/` |
| Best for | "Does my new feature work?", smoke after refactor, debugging unresponsive UI | Regression-proof test suites in CI |
| Build mode | Debug only (requires VM Service) | Debug + release (via Patrol runner) |

Rules of thumb:
- Iterating on a new feature and want the agent to click around? **Marionette.**
- Writing a repeatable E2E test that runs in CI? **Patrol** (see `flutter-patrol` plugin).
- Want quick visual verification after a change without writing tests? **Marionette.**

## App preparation

Prepare the Flutter app before trying to drive it:

- Add `marionette_flutter` to the app.
- Install the MCP server either as a global tool (`dart pub global activate marionette_mcp`) or as a dev dependency (`dart pub add dev:marionette_mcp`) and run it with `dart run marionette_mcp`.

## Available MCP tools

When the `marionette` MCP server is configured and connected, use these tools:

- `connect` / `disconnect` — manage the VM service connection. Call `connect` first, passing the `ws://127.0.0.1:PORT/ws` URI printed by `flutter run`.
- `get_interactive_elements` — retrieve the list of currently tappable / actionable UI components. **Always call this before `tap` / `enter_text`** to see what is available and to get stable identifiers.
- `tap` — simulate a button or element press.
- `enter_text` — input data into a text field.
- `scroll_to` — scroll an off-screen element into view.
- `take_screenshots` — capture the current app visuals as base64. Use to verify visual state after an action or to debug why something is not found.
- `get_logs` — retrieve application logs. Use when an action silently fails or state is unclear.
- `hot_reload` — apply code changes without losing app state. Useful when iterating on a feature and wanting to re-check it without restarting.

## Binding initialization

Initialize `MarionetteBinding` in `main.dart` under `kDebugMode` so it compiles out of release builds:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(const MyApp());
}
```

For apps with a custom design system, pass a `MarionetteConfiguration` — see `marionette-widget-config.md`.

`MarionetteBinding` must be the only binding initialized in the process. If tests call `main()` while `kDebugMode` is true, avoid initializing Marionette in tests by checking `FLUTTER_TEST` or by using a separate test entrypoint.

## Log collection

`get_logs` works only when a `LogCollector` is configured.

- For apps using the `logging` package, use `LoggingLogCollector()`.
- For apps using the `logger` package, use `LoggerLogCollector()`.
- For other setups, use `PrintLogCollector()` and forward logs into it.
- If no collector is configured, `get_logs` should explain how to enable it.

## Workflow: driving the app as an agent

1. Start the app: `flutter run` (take note of the VM service URI).
2. Call `connect` with the URI.
3. Call `get_interactive_elements` to see what is on screen.
4. Act: `tap`, `enter_text`, `scroll_to`.
5. Call `take_screenshots` to verify visual state (and when the element list looks wrong).
6. Use `get_logs` if an action has no visible effect.
7. Call `hot_reload` after a code change to re-test without losing state.
8. Call `disconnect` when finished.

## Best-effort caveat

Marionette simulates gestures best-effort. Results may vary with platform differences, overlays, and custom widget implementations. If interactions are flaky:

- Expose clearer widget keys.
- Simplify hit targets (avoid deeply nested `GestureDetector`s).
- Add `isInteractiveWidget` / `extractText` hooks for custom widgets — see `marionette-widget-config.md`.

## The agent does not understand your app flow

Marionette observes the UI but does not automatically know your product's flows, naming conventions, or edge cases. When prompting the AI:

- Describe expected screen names, widget keys, and labels.
- State preconditions (e.g. "assume user is already logged in").
- State the interaction goal in one sentence.

## Build-mode constraint

Marionette relies on Flutter's VM Service and is designed to drive a live `flutter run` session. It does not work in release builds. For release-mode automation use Patrol instead.
