# Text Prompts and Validation

Ask a free-form question and validate the answer before accepting it.

## Overview

A text prompt is described by ``TextPrompt``, a plain value type. You never
call anything on `TextPrompt` directly. Instead, you build one and hand it
to ``Terminal/readText(_:)`` (or the shortcut ``InteractionProviding/textPrompt(title:prompt:description:collapsesOnAnswer:validationRules:)``),
which does the actual reading:

```swift
let terminal = Terminal()

let name = terminal.readText(
    TextPrompt(message: "What is your name?")
)
```

Or, using the shortcut that skips building the struct yourself:

```swift
let name = terminal.textPrompt(prompt: "What is your name?")
```

Both calls are equivalent. The shortcut's parameter is named `prompt:` but it
fills in `TextPrompt.message`.

### Adding a title and description

`title` is rendered above the question; `description` is supporting text
rendered alongside it. Both are optional and default to `nil`:

```swift
let path = terminal.readText(
    TextPrompt(
        title: "Project Setup",
        message: "Where should the project be created?",
        description: "A relative or absolute path. The directory is created if it doesn't exist."
    )
)
```

### Validating the answer

Pass one or more ``ValidationRule`` values in `validationRules`. The prompt
will not accept an answer until every rule passes. On failure, the terminal
prints each rule's error message and asks again:

```swift
let moduleName = terminal.readText(
    TextPrompt(
        message: "Module name",
        validationRules: [NonEmptyRule()]
    )
)
```

``NonEmptyRule`` is the only validation rule the library ships. It rejects an
empty string (`input.isEmpty`). Note that this checks for *empty*, not
*blank*: a string of only spaces passes.

#### Writing your own validation rule

Conform to ``ValidationRule`` directly if you need full control over the
returned error:

```swift
struct MaxLengthRule: ValidationRule {
    let limit: Int

    func validate(_ input: String) -> ValidationError? {
        input.count <= limit ? nil : ValidationError("Must be \(limit) characters or fewer.")
    }
}
```

For the common case of "a predicate plus one fixed error message", conform to
``PredicateValidationRule`` instead. It supplies `validate(_:)` for you from
a simpler `validate(input:)` boolean and an `error`:

```swift
struct AlphanumericRule: PredicateValidationRule {
    let error = ValidationError("Only letters and numbers are allowed.")

    func validate(input: String) -> Bool {
        input.allSatisfy(\.isLetter) || input.allSatisfy(\.isNumber)
    }
}
```

Multiple rules can be combined in the same array; every rule that fails
contributes its error, so the user sees all problems with their answer at
once, not just the first one.

## Yes/no confirmation

``ConfirmationPrompt`` asks a yes/no question and resolves to a `Bool`, via
``Terminal/confirm(_:)`` or the ``InteractionProviding/yesOrNoChoicePrompt(title:question:defaultAnswer:description:collapsesOnAnswer:)``
shortcut:

```swift
let proceed = terminal.confirm(
    ConfirmationPrompt(question: "Delete 3 files?", defaultAnswer: false)
)
```

`defaultAnswer` is what gets returned when the user submits an empty answer
(presses Enter without typing, or enters an empty line in a non-interactive
terminal). Set it to `false` for destructive or otherwise sensitive
confirmations, so an empty answer doesn't accidentally mean "yes."

## Terminal environments without a TTY

When the process isn't attached to an interactive terminal (piped input,
CI logs, `NO_COLOR`-style dumb terminals), `Terminal` automatically falls
back to plain line-based prompting: it prints the question, reads one line at
a time with `readLine()`, and re-prompts on validation failure. The same
rules and defaults apply, just without arrow-key navigation or live
in-place redrawing.

If standard input is closed (end-of-file, or the process receives Ctrl-D)
before an answer is given, `Terminal` **fails closed**: it prints an error
and exits the process rather than silently substituting a default answer.
This matters most for ``ConfirmationPrompt``, where silently defaulting on
EOF could otherwise approve a destructive action nobody actually confirmed.
