# ``Interaction``

Build terminal interactions for macOS command line tools, including prompts, choices, tables, and styled text.

## Overview

Interaction is a terminal interaction library for Swift. It provides text
prompts, single- and multiple-choice selection, table rendering, styled text,
validation primitives, and terminal capability detection.

``Terminal`` is the entry point: construct one and call ``Terminal/readText(_:)``,
``Terminal/confirm(_:)``, ``Terminal/choose(_:)``, ``Terminal/chooseMany(_:)``,
``Terminal/write(_:)``, and ``Terminal/writeTable(_:)``.

It powers the interactive command line experience in the egg scaffolding tool,
and can be adopted by any macOS Swift CLI that needs a polished, testable
terminal UI layer.

## Topics

### Getting Started

- <doc:GettingStarted>

### Terminal

- ``Terminal``
- ``TerminalCapabilities``
- ``InteractionProviding``

### Prompts

- ``TextPrompt``
- ``ChoicePrompt``
- ``MultipleChoicePrompt``
- ``ConfirmationPrompt``
- ``ChoiceOption``

### Styling and Layout

- ``StyledText``
- ``Table``

### Validation

- ``ValidationRule``
- ``ValidationError``
- ``NonEmptyRule``
