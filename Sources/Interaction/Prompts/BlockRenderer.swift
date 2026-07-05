/// The result of running an interactive prompt loop.
enum InteractiveOutcome<Value> {
    /// The user answered the prompt.
    case answered(Value)
    /// The user pressed Ctrl-C.
    case interrupted
    /// Standard input was exhausted.
    case inputClosed
}

/// Redraws a block of terminal lines in place.
struct BlockRenderer {
    private let output: any TextOutput
    private var renderedLineCount = 0
    private var cursorLine = 0

    init(output: any TextOutput) {
        self.output = output
    }

    /// Replaces the previously rendered block with new lines, optionally
    /// leaving the terminal cursor at a position inside the block.
    mutating func render(_ lines: [String], cursor: (line: Int, column: Int)? = nil) {
        var text = rewindSequence() + lines.joined(separator: "\n") + "\n"

        if let cursor {
            // Move up from the last printed line to the requested cursor line, then
            // return to column 0 (`\r`) before nudging right (`C`) if needed.
            text += "\u{1B}[\(lines.count - cursor.line)A\r"
            if cursor.column > 0 {
                text += "\u{1B}[\(cursor.column)C"
            }
            cursorLine = cursor.line
        } else {
            cursorLine = lines.count
        }

        output.write(text)
        renderedLineCount = lines.count
    }

    /// Erases the previously rendered block.
    mutating func clear() {
        output.write(rewindSequence())
        renderedLineCount = 0
        cursorLine = 0
    }

    /// Moves the cursor back to the top-left of the previously rendered block and
    /// erases everything from there to the end of the screen, so the next `render`
    /// overwrites it in place instead of appending below it.
    private func rewindSequence() -> String {
        guard renderedLineCount > 0 else { return "" }
        let up = cursorLine > 0 ? "\u{1B}[\(cursorLine)A" : ""
        return "\r" + up + "\u{1B}[0J"
    }
}
