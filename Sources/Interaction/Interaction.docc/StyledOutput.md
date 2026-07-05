# Styled Text and Tables

Print semantically-styled text and aligned tables that degrade gracefully
when color or width isn't available.

## Overview

``StyledText`` is a small, `String`-literal-like type that carries semantic
styling (success, danger, muted, and so on) instead of raw ANSI codes. You
build it with ordinary string interpolation, and it renders differently
depending on whether the terminal supports color:

```swift
let terminal = Terminal()

terminal.write("Plain text works exactly like a string literal.")
terminal.write("\(StyledText.Segment.success("Build succeeded")) in 2.3s")
```

Because `StyledText` conforms to `ExpressibleByStringInterpolation`, any
`String`-typed API in this library (`TextPrompt.message`, `Table` cells via
`StyledText`, and so on) also accepts a `StyledText` literal directly.

### Semantic segments

``StyledText/Segment`` cases describe *why* text is styled, not how it
looks. The actual ANSI color is an implementation detail, so it can change
without breaking callers:

| Segment | Typical use |
|---|---|
| `.primary` | Emphasized text (rendered bold) |
| `.secondary` | De-emphasized text (no color change) |
| `.muted` | Low-emphasis labels (rendered dim) |
| `.accent` | Highlights and warnings (rendered yellow) |
| `.danger` | Errors and destructive actions (rendered red) |
| `.success` | Successful outcomes (rendered green) |
| `.info` | Informational notes (rendered blue) |
| `.command` | Shell commands or code (rendered cyan) |
| `.path` | File paths (rendered cyan) |
| `.link(title:destination:)` | A labeled link (rendered underlined blue) |
| `.plain` | No styling at all |

Build one by interpolating a segment case into a `StyledText` literal:

```swift
let message: StyledText = "Run \(StyledText.Segment.command("swift test")) before committing."
```

### Status messages

``Terminal/writeStatus(_:_:)`` prefixes a message with a colored tag for one
of four ``Status`` categories: `.success`, `.failure`, `.warning`, or
`.info`. The shorter convenience methods wrap it directly:

```swift
terminal.writeSuccess("All checks passed.")
terminal.writeFailure("3 tests failed.")
terminal.writeWarning("Deprecated flag used.")
terminal.writeInfo("Using cached build artifacts.")
```

### Plain lines and indentation

``InteractionProviding/writeLine(_:tab:indentSpace:)`` writes one line
(followed by a newline), optionally indented. Call it with no arguments to
print a blank line:

```swift
terminal.writeLine("Templates:")
terminal.writeLine("SwiftPackage", tab: 1)   // indented by one level (4 spaces)
terminal.writeLine()                          // blank line
```

`tab` is the indentation level and `indentSpace` is how many spaces make up
one level (default `4`); a `tab` of `2` with the default `indentSpace`
indents by 8 spaces.

### When color isn't available

`Terminal` detects color support automatically (see
<doc:TerminalEnvironment>) and renders every ``StyledText`` value as plain
text when color isn't supported. No ANSI escape codes are emitted in that
case, and no call site needs to check for this itself.

## Tables

``Table`` is a plain list of headers and rows; ``Terminal/writeTable(_:)``
renders it as a bordered, column-aligned box using the terminal's detected
width.

```swift
let table = Table(
    headers: ["Name", "Status"],
    rows: [
        ["SwiftPackage", "ready"],
        ["iOSApp", "ready"],
    ]
)
terminal.writeTable(table)
```

### Building a table with the result builder

For tables assembled conditionally or in a loop, use the `@TableBuilder`
initializer instead of passing arrays directly:

```swift
let table = Table {
    TableHeader("Name", "Status")
    for template in templates {
        TableRow(template.name, template.isReady ? "ready" : "pending")
    }
}
```

`TableHeader` and `TableRow` accept `String` values, ``StyledText`` values
(reduced to their plain text), or anything `CustomStringConvertible`. Only
the *last* `TableHeader` in the builder is used if more than one is present;
every `TableRow` is kept, in order.

### How rendering handles width and wrapping

``TableRenderer`` (used internally by `Terminal.writeTable`, but usable on
its own if you want the rendered string instead of writing it immediately)
computes each column's natural width from its widest cell, using
Unicode-aware display width instead of `String.count`, so CJK text, emoji,
and combining characters measure correctly.

If a maximum width is supplied (`Terminal` passes the detected terminal
width automatically), columns that don't fit are shrunk one at a time,
narrowest last, down to a minimum of one character per column. Cell text
that's too long for its column wraps at whitespace where possible; a single
word too long for the column is broken mid-word without splitting a Unicode
grapheme cluster (so multi-byte characters are never corrupted).

A table with no headers and no rows renders as an empty string rather than
an empty pair of borders.
