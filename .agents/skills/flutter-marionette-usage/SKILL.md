---
name: flutter-marionette-usage
description: Explain what the `flutter-marionette` plugin does and how to use it. Use when the user invokes `/flutter-marionette-usage`, asks what this plugin covers, or needs help with Marionette MCP setup, runtime exploration, or custom widget configuration.
---

# Marionette Usage

## How to respond

- If the user invoked this skill without a concrete task, start by explaining what Marionette is for and when it is better than writing tests.
- Show how to use it with concrete runtime-exploration tasks this plugin can handle.
- Point to the relevant rule or README section for setup, widget configuration, or tool boundaries.
- If the user already gave a concrete Marionette task, briefly explain why this plugin fits and then do the work.
- Do not reply with filler like "skill loaded", "ready for the task", or "what would you like to do?" before explaining the plugin.

## What this plugin does

- Helps an AI agent interact with a live Flutter debug app through Marionette MCP.
- Covers setup, runtime connection, log collection, and custom widget configuration.
- Clarifies when Marionette is the right tool for smoke verification or debugging, and when Patrol is a better fit for deterministic E2E tests.

## How to use it

- Ask how to connect Marionette to a running `flutter run` session.
- Ask to verify or debug an interactive flow without creating test files.
- Ask how to configure Marionette for a custom design-system widget.
- Ask to troubleshoot setup issues around bindings, VM service connection, or log collection.

## Example requests

- "Help me connect Marionette to my running Flutter app."
- "Use Marionette to smoke-test the onboarding flow."
- "How should I configure Marionette for this custom button component?"

## Reach for these assets

- `references/marionette.md` - Marionette workflow, setup, and tool boundaries.
- `references/marionette-widget-config.md` - interactive-widget and text-extraction configuration.
- `README.md` - complete setup sequence and VM service connection details.
- Related plugin: `flutter-patrol` - deterministic E2E testing with Patrol.
