# Getting Started

Add Interaction to a package and drive your first prompt.

## Add the dependency

```swift
// Package.swift
.package(url: "https://github.com/Ryu0118/swift-interaction", from: "0.1.0"),
```

Then add `"Interaction"` — as `.product(name: "Interaction", package: "swift-interaction")` — to your target's dependencies.

## Read text and confirm

```swift
import Interaction

let terminal = Terminal()

let name = terminal.readText(TextPrompt(message: "What is your name?"))
let proceed = terminal.confirm(ConfirmationPrompt(question: "Continue?"))
```

## Next steps

Explore ``ChoicePrompt`` and ``MultipleChoicePrompt`` for selection menus,
``Table`` for tabular output, ``StyledText`` for semantic styling, and
``ValidationRule`` for validated input.
