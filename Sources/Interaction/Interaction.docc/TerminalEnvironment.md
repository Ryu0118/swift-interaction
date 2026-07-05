# Terminal Environment and Custom Backends

Understand how `Terminal` detects its environment, what happens on
interruption or EOF, and how to swap in your own I/O for testing or
non-standard backends.

## Overview

Everything in this library that reads or writes to a terminal goes through
``InteractionProviding``, a protocol with seven requirements: `write`,
`writeStatus`, `writeTable`, `readText`, `confirm`, `choose`, and
`chooseMany`. ``Terminal`` is the library's production implementation of
that protocol; every convenience method described elsewhere in this
documentation (``InteractionProviding/writeLine(_:tab:indentSpace:)``,
``InteractionProviding/textPrompt(title:prompt:description:collapsesOnAnswer:validationRules:)``,
and so on) is defined as a `public extension` on the protocol, so it works
identically on `Terminal` or on any custom conformer.

## Detecting the environment

``TerminalCapabilities`` describes what the current process can do:

```swift
let capabilities = TerminalCapabilities.detect()
capabilities.isInteractive  // can we use raw-mode arrow-key prompts?
capabilities.supportsColor  // should StyledText render ANSI codes?
capabilities.width          // detected column width, if known
```

`Terminal()` calls `.detect()` automatically, so you rarely need to call it
yourself. It's public mainly so tests can construct a `Terminal` with fixed
capabilities instead of depending on the real process environment:

```swift
let nonInteractiveTerminal = Terminal(
    capabilities: TerminalCapabilities(isInteractive: false, supportsColor: false)
)
```

Detection rules:
- `isInteractive` is `true` only when both stdin and stdout are attached to a
  TTY and `TERM` is not `"dumb"`.
- `supportsColor` is `true` when stdout is a TTY, `TERM` isn't `"dumb"`, and
  the `NO_COLOR` environment variable isn't set to a non-empty value (per the
  [NO_COLOR](https://no-color.org) convention).
- `width` comes from the `COLUMNS` environment variable if it's set to a
  positive integer, otherwise from an `ioctl` query of the terminal window
  size; it's `nil` when stdout isn't a TTY and `COLUMNS` isn't set.

## What changes when the terminal isn't interactive

When `capabilities.isInteractive` is `false` (piped input, CI logs, a dumb
terminal), every prompt method falls back to a plain, line-based mode
instead of the arrow-key-navigable interactive mode:

- ``Terminal/readText(_:)`` prints the question and reads one line at a
  time, re-prompting on validation failure.
- ``Terminal/confirm(_:)`` prints a `[Y/n]`/`[y/N]` suffix based on the
  prompt's default answer and reads one line; an empty line accepts the
  default.
- ``Terminal/choose(_:)`` and ``Terminal/chooseMany(_:)`` print a numbered
  list and read one number (or, for multiple choice, several
  comma-/space-separated numbers).

The same validation rules, minimum/maximum selection counts, and default
answers apply in both modes. Only the interaction style changes.

## Interruption and end-of-input

Interactive prompts handle two special cases the same way everywhere in the
library:

- **Ctrl-C (interrupt):** the process exits immediately with status `130`,
  the conventional exit code for a SIGINT-terminated process.
- **Ctrl-D / closed stdin (end of input):** the process prints an error to
  standard error and exits with a failure status, rather than returning a
  default value.

The end-of-input behavior is a deliberate fail-closed design: for a
``ConfirmationPrompt``, silently substituting `defaultAnswer` when input is
unexpectedly closed could approve a destructive action nobody actually
confirmed. If your program needs to run unattended, provide input up front
(for example, by piping answers) rather than relying on defaults kicking in
when input runs out.

## Building a custom backend

`Terminal`'s constructor accepts every I/O dependency, so you can substitute
your own for testing or for backends other than the real process stdin/stdout:

```swift
struct ScriptedInput: TextInput {
    var lines: [String]
    func readLine() -> String? { lines.isEmpty ? nil : lines.removeFirst() }
}

let terminal = Terminal(
    input: ScriptedInput(lines: ["my-project"]),
    output: StandardOutput(),
    capabilities: TerminalCapabilities(isInteractive: false, supportsColor: false)
)
```

`TextInput` and `TextOutput` cover the line-based fallback path.
``KeyInput`` covers the raw, byte-at-a-time path used by the interactive
mode (``TerminalKey`` is the decoded key event type: character keys, arrow
keys, enter, backspace, delete, interrupt, and end-of-input). Conforming
types get a no-op `withRawInput` for free via a protocol extension, so you
only need to implement it yourself if your backend has an actual raw-mode
concept to toggle.

You can also conform your own type to ``InteractionProviding`` directly
instead of using `Terminal` at all, if you want to back the same prompt
types with something other than a real terminal, such as a test recorder or
a different presentation layer entirely.
