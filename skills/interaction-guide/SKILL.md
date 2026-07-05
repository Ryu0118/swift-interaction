---
name: interaction-guide
description: |
  Use the Interaction Swift library to build terminal UIs. Use when a developer wants to: (1) prompt for text input with validation, (2) present single- or multiple-choice menus, (3) render tables or styled/colored text, (4) confirm yes/no, or (5) detect terminal capabilities. Covers the public API of the `Interaction` module.
---

# Interaction API Guide

`Interaction` is a Swift library for terminal interaction on macOS 26+.

## Add the dependency

```swift
.package(url: "https://github.com/Ryu0118/swift-interaction", from: "0.1.0"),
// target dep: .product(name: "Interaction", package: "swift-interaction")
```

## Entry point: `Terminal`

`Terminal` is the entry point. Construct one and drive prompts against it:

```swift
import Interaction

let terminal = Terminal()

let name = terminal.readText(TextPrompt(message: "What is your name?"))
let proceed = terminal.confirm(ConfirmationPrompt(question: "Continue?"))
```

`Terminal`'s methods: `readText(_:)`, `confirm(_:)`, `choose(_:)`,
`chooseMany(_:)`, `write(_:)`, `writeStatus(_:_:)`, `writeTable(_:)`.

## Text prompts

`TextPrompt(message:)` reads a line of input. Attach `validationRules:` for
built-in validation. `ValidationRule`, `NonEmptyRule`, and `ValidationError`
live in the same module.

```swift
let value = terminal.readText(
    TextPrompt(message: "Module name", validationRules: [NonEmptyRule()])
)
```

## Single / multiple choice

`ChoicePrompt<Option>` and `MultipleChoicePrompt<Option>` present arrow-key
navigable, filterable menus. `Option` must be `Equatable & CustomStringConvertible & Sendable`.

```swift
let choice = terminal.choose(ChoicePrompt(question: "Pick one", options: [...]))
let many = terminal.chooseMany(MultipleChoicePrompt(question: "Pick some", options: [...]))
```

## Styled text and tables

`StyledText` provides semantic segments (`primary`, `muted`, `accent`, `danger`,
`success`, `info`, `path`, `command`, `link`) that render with ANSI color when
the terminal supports it. `Table` renders aligned output via
`terminal.writeTable(_:)`.

## Terminal capabilities

`TerminalCapabilities` detects color support, interactivity, and size so output
degrades gracefully in non-TTY contexts.

## Reference

The full API is documented at
[ryu0118.github.io/swift-interaction/documentation/interaction](https://ryu0118.github.io/swift-interaction/documentation/interaction/),
but that page renders its content with JavaScript, so a plain fetch of it
returns an empty shell. For agents, fetch the underlying DocC data instead —
it's plain JSON, one file per symbol, lowercased:

```
https://ryu0118.github.io/swift-interaction/data/documentation/interaction.json           # module overview
https://ryu0118.github.io/swift-interaction/data/documentation/interaction/terminal.json   # Terminal
https://ryu0118.github.io/swift-interaction/data/documentation/interaction/textprompt.json # TextPrompt
```

Exact initializer labels and signatures are authoritative there, so check
before relying on a snippet here.
