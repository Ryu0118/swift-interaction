# 🖥️ Interaction

**A terminal interaction library for Swift, providing prompts, choices,
tables, and styled text for macOS command line tools.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-macOS%2026%2B-lightgrey)](https://developer.apple.com/macos/)

Interaction gives any macOS Swift CLI a polished, testable terminal UI layer.

## Features

- ⌨️ Read validated text input using the built-in `NonEmptyRule` or your own
  types conforming to `ValidationRule` and `PredicateValidationRule`.
- 📋 Present arrow-key navigable, filterable single- and multiple-choice menus.
- 🎨 Render semantic ANSI-styled text and aligned tables that degrade
  gracefully in non-TTY contexts.

## Quick Start for Agents

Install the plugin for your agent, then ask it how to use the Interaction API.

### Claude Code

```sh
/plugin marketplace add Ryu0118/swift-interaction
/plugin install interaction@interaction
```

### Codex

```sh
codex plugin marketplace add Ryu0118/swift-interaction
codex plugin add interaction@interaction
```

The plugin provides the `interaction-guide` skill covering prompts, choices,
tables, styled text, and validation.

## Quick Start for Humans

`Terminal` is the entry point. Construct one and drive prompts against it:

```swift
import Interaction

let terminal = Terminal()

// Text input
let name = terminal.readText(TextPrompt(message: "What is your name?"))

// Yes/no confirmation
let proceed = terminal.confirm(ConfirmationPrompt(question: "Continue?"))

// Single choice
let choice = terminal.choose(
    ChoicePrompt(question: "Pick one", options: ["a", "b", "c"])
)
```

`ChoicePrompt`/`MultipleChoicePrompt` options are any
`Equatable & CustomStringConvertible & Sendable` type. See the DocC docs and the
`interaction-guide` skill for the full, current API.

## Installation

Add Interaction to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Ryu0118/swift-interaction", from: "0.1.0"),
],
```

Then add it to your target:

```swift
.target(
    name: "YourCLI",
    dependencies: [
        .product(name: "Interaction", package: "swift-interaction"),
    ]
),
```

Requires **macOS 26+** and **Swift 6.2**.

## Documentation

Full API documentation is published at
[ryu0118.github.io/swift-interaction](https://ryu0118.github.io/swift-interaction/).

The DocC catalog lives in `Sources/Interaction/Interaction.docc`. Generate the
archive locally with SwiftPM:

```sh
make docs
```

## Development

```sh
make install-commands
make format
make lint
make test
make check
```

## License

Interaction is available under the MIT License. See [LICENSE](LICENSE) for details.
