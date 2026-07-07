# ``Interaction``

Build terminal interactions for macOS command line tools, including prompts, choices, tables, and styled text.

## Overview

Interaction is a terminal interaction library for Swift. It provides text
prompts, single- and multiple-choice selection, table rendering, styled text,
validation primitives, and terminal capability detection.

``Terminal`` is the entry point: construct one and call ``Terminal/readText(_:)``,
``Terminal/confirm(_:)``, ``Terminal/choose(_:)``, ``Terminal/chooseMany(_:)``,
``Terminal/write(_:)``, and ``Terminal/writeTable(_:)``.

It can be adopted by any macOS Swift CLI that needs a polished, testable
terminal UI layer.

## Topics

### Getting Started

- <doc:GettingStarted>

### Text Prompts and Validation

- <doc:TextPrompts>
- ``TextPrompt``
- ``ConfirmationPrompt``
- ``ValidationRule``
- ``ValidationError``

### Choice Menus

- <doc:ChoiceMenus>
- ``ChoicePrompt``
- ``MultipleChoicePrompt``
- ``ChoiceOption``
- ``SingleSelectionState``
- ``MultipleSelectionState``

### Styled Text and Tables

- <doc:StyledOutput>
- ``StyledText``
- ``StyledTextRenderer``
- ``Table``
- ``TableHeader``
- ``TableRow``
- ``TableRenderer``
- ``TableBuilder``
- ``TableCellBuilder``
- ``TableElement``

### Terminal Environment and Custom Backends

- <doc:TerminalEnvironment>
- ``Terminal``
- ``TerminalCapabilities``
- ``InteractionProviding``
- ``Status``
- ``TextInput``
- ``TextOutput``
- ``StandardInput``
- ``StandardOutput``
- ``KeyInput``
- ``TerminalKey``
- ``StandardKeyInput``
- ``LineBuffer``
