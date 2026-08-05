# Marionette Widget Configuration

Marionette recognizes standard Flutter widgets automatically. Custom design-system widgets (e.g. `MyPrimaryButton` wrapping `GestureDetector`, or `MyText` wrapping `Text`) require explicit configuration or they will not appear in `get_interactive_elements` results.

Configure them via two callbacks on `MarionetteConfiguration`.

## `isInteractiveWidget`

Marks a widget type as an actionable target — a button, text field, switch, slider, etc. Without this, Marionette cannot distinguish your `MyPrimaryButton` from a plain `Padding`.

```dart
MarionetteConfiguration(
  isInteractiveWidget: (type) =>
      type == MyPrimaryButton ||
      type == MySecondaryButton ||
      type == MyTextField ||
      type == MyToggle,
)
```

## `extractText`

Serves two purposes: (1) makes widgets with extractable text appear in the interactive element tree (useful for discovery even if not strictly interactive), (2) powers text-based matching for `tap` / `scroll_to`.

The callback receives an `Element` object, so you can walk the element subtree — essential when widget properties like labels or placeholders are `Widget` instances rather than plain strings.

Marionette already extracts text from standard Flutter widgets such as `Text`, `RichText`, `EditableText`, `TextField`, and `TextFormField`. Use `extractText` to add support for custom widgets.

Simple case — text is a plain string on the widget:

```dart
MarionetteConfiguration(
  extractText: (element) {
    final widget = element.widget;
    if (widget is MyText) return widget.data;
    return null;
  },
)
```

Complex case — text lives deeper in the widget subtree:

```dart
String? _extractMyTextFieldText(Element element, MyTextField widget) {
  final decorator = _findElementOfType<MyInputDecorator>(element);
  if (decorator != null) {
    final decoratorWidget = decorator.widget as MyInputDecorator;
    if (decoratorWidget.label != null) {
      return _findTextInWidgetSlot(decorator, decoratorWidget.label!);
    }
  }
  return widget.controller?.text;
}
```

Helper patterns: `_findElementOfType<T>(element)` walks the subtree to locate the first descendant of type `T`; `_collectText` / `_findTextInWidgetSlot` accumulate rendered text from a subtree. Implement these as private helpers next to the config.

## Full configuration example

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(
        isInteractiveWidget: (type) =>
            type == MyPrimaryButton || type == MyTextField,
        extractText: (element) {
          final widget = element.widget;
          if (widget is MyText) return widget.data;
          if (widget is MyTextField) {
            return _extractMyTextFieldText(element, widget);
          }
          return null;
        },
      ),
    );
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  runApp(const MyApp());
}
```

## Where to put the configuration

For small apps: inline directly in `main.dart` inside the `kDebugMode` branch.

For apps with a non-trivial design system: extract to a dedicated file (e.g. `lib/debug/marionette_config.dart`) that is imported only behind `kDebugMode`. This keeps release builds free of design-system introspection helpers.

## Screenshot sizing

By default, `take_screenshots` downscales captures to fit within 2000×2000 physical pixels. Override via `maxScreenshotSize` on `MarionetteConfiguration` (set to `null` for no downscaling):

```dart
MarionetteConfiguration(
  maxScreenshotSize: const Size(1200, 1200),
  // ...
)
```

Larger screenshots mean larger base64 payloads to the MCP client — keep the default unless there's a specific reason to raise it.

## Covering custom widgets — when to add vs defer

Add a widget to `isInteractiveWidget` / `extractText` when:

- It is a primary interactive primitive in the design system (button, field, toggle, tab, chip).
- The AI agent's `get_interactive_elements` output is noticeably missing it.

Defer when:

- The widget is used only in non-interactive contexts (e.g. decorative badges).
- The underlying primitive is already covered (e.g. `MyCard` wraps a `GestureDetector` that Marionette already sees).

The list is not meant to be exhaustive — add entries as the agent reports missing targets in real use.
