# Choice Menus

Let the user pick one option, or several, from a list.

## Overview

Like text prompts, a choice menu is described by a plain value type. Use
``ChoicePrompt`` for picking one option, or ``MultipleChoicePrompt`` for
picking several, and read it with ``Terminal/choose(_:)`` or
``Terminal/chooseMany(_:)``.

Options can be any type that is `Equatable`, `CustomStringConvertible`, and
`Sendable`, including `String` itself:

```swift
let terminal = Terminal()

let environment = terminal.choose(
    ChoicePrompt(question: "Deploy to which environment?", options: ["staging", "production"])
)
```

The shortcut ``InteractionProviding/singleChoicePrompt(title:question:options:description:allowsFiltering:collapsesOnSelection:automaticallySelectsSingleOption:)``
does the same thing without building the struct yourself:

```swift
let environment = terminal.singleChoicePrompt(
    question: "Deploy to which environment?",
    options: ["staging", "production"]
)
```

### Choosing from your own types

Any type conforming to `Equatable & CustomStringConvertible & Sendable` works
as an option. `CustomStringConvertible`'s `description` is what's shown in
the menu:

```swift
struct Environment: Equatable, CustomStringConvertible, Sendable {
    let name: String
    var description: String { name }
}

let chosen = terminal.choose(
    ChoicePrompt(question: "Pick an environment", options: [Environment(name: "staging"), Environment(name: "production")])
)
```

If you need a display label that differs from the value itself, use
``ChoiceOption`` when constructing the underlying ``SingleSelectionState`` or
``MultipleSelectionState`` directly (see below) rather than `ChoicePrompt`,
which shows each option's own `description`.

### Multiple selection

``MultipleChoicePrompt`` and ``Terminal/chooseMany(_:)`` return `[Option]`
instead of a single `Option`. Use `minimumSelectionCount` and
`maximumSelectionCount` to constrain how many the user must or may pick:

```swift
let features = terminal.chooseMany(
    MultipleChoicePrompt(
        question: "Which features do you want?",
        options: ["logging", "analytics", "crash-reporting"],
        minimumSelectionCount: 1
    )
)
```

`minimumSelectionCount` defaults to `0` (nothing required) and
`maximumSelectionCount` defaults to `nil` (no upper bound).

### Filtering long lists

Both prompt types default `allowsFiltering` to `true`, which lets the user
type to narrow the visible options by a case- and diacritic-insensitive
substring match against each option's label. Set it to `false` to disable
filtering, e.g. for menus short enough that filtering adds nothing.

### Automatic single-option selection

``ChoicePrompt/automaticallySelectsSingleOption`` defaults to `true`. If the
options array has exactly one element, `Terminal.choose` returns it
immediately with no prompt shown at all, which is useful when a menu's
option list is computed and can sometimes collapse to a single valid choice.
Set it to `false` if you always want the user to see and confirm the option,
even when there's only one.

## Non-empty options are required

Both `Terminal.choose(_:)` and `Terminal.chooseMany(_:)` require at least one
option: calling either with an empty `options` array is a programmer error
and crashes the process (a Swift `precondition` failure), not a recoverable
error. Always ensure the options array is non-empty before presenting the
prompt.

## Building selection state directly

``SingleSelectionState`` and ``MultipleSelectionState`` are the cursor- and
filter-tracking value types that back the interactive menus internally.
They're public so you can build custom UI on top of the same selection
logic, but most consumers of this library will only ever go through
``ChoicePrompt``/``MultipleChoicePrompt`` and never touch them directly.

``SingleSelectionState`` tracks a cursor position over a filtered view of
``ChoiceOption`` values:

```swift
var state = SingleSelectionState(
    options: [ChoiceOption("staging"), ChoiceOption("production")]
)
state.moveDown()      // wraps to the first option if already at the last
state.selected        // the ChoiceOption currently under the cursor
state.filter = "prod" // re-filters visibleOptions and clamps the cursor
```

``ChoiceOption`` pairs a `value` with an optional display `label`. If you
don't supply one, it defaults to `value.description`.

``MultipleSelectionState`` wraps the same cursor/filter behavior and adds a
set of selected indexes:

```swift
var state = MultipleSelectionState(
    options: [ChoiceOption("logging"), ChoiceOption("analytics")],
    minimumSelectionCount: 1
)
state.toggleFocusedOption() // selects/deselects the option under the cursor
state.selectedValues        // selected values, in original option order
```

`toggleFocusedOption()` respects the configured bounds: it refuses to
deselect an option if doing so would drop the selection count below
`minimumSelectionCount`, and refuses to select a new option once
`maximumSelectionCount` is already reached.

## Terminal environments without a TTY

When there's no interactive terminal attached, both prompt types fall back
to a numbered list: options are printed with 1-based numbers, and the user
types the number (or, for multiple choice, a comma- or space-separated list
of numbers) instead of navigating with arrow keys. The same minimum/maximum
selection constraints are enforced in this mode too.
