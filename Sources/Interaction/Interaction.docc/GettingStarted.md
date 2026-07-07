# Getting Started

Add Interaction to a package and drive your first prompt.

## Add the dependency

```swift
// Package.swift
.package(url: "https://github.com/Ryu0118/swift-interaction", from: "0.1.0"),
```

Then add `.product(name: "Interaction", package: "swift-interaction")` to your target's dependencies.

## Read text and confirm

```swift
import Interaction

let terminal = Terminal()

let name = await terminal.readText(TextPrompt(message: "What is your name?"))
let proceed = terminal.confirm(ConfirmationPrompt(question: "Continue?"))
```

## Next steps

- <doc:TextPrompts> covers validated text input and yes/no confirmations in
  depth.
- <doc:ChoiceMenus> covers single- and multiple-choice menus, filtering, and
  selection limits.
- <doc:StyledOutput> covers semantic text styling and table rendering.
- <doc:TerminalEnvironment> covers capability detection, non-interactive
  fallbacks, and building a custom backend.
