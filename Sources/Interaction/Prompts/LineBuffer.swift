/// A Unicode-aware editable line buffer for terminal text input.
public struct LineBuffer: Equatable, Sendable {
    private var characters: [Character]

    /// The cursor offset measured in grapheme clusters.
    public private(set) var cursorOffset: Int

    public init(_ text: String = "") {
        characters = Array(text)
        cursorOffset = characters.count
    }

    /// The full text currently held by the buffer.
    public var text: String {
        String(characters)
    }

    /// The terminal display column of the cursor.
    public var cursorDisplayColumn: Int {
        String(characters.prefix(cursorOffset)).terminalDisplayWidth
    }

    /// Replaces the entire buffer and moves the cursor to the end.
    public mutating func replace(with text: String) {
        characters = Array(text)
        cursorOffset = characters.count
    }

    /// Inserts text at the current cursor position.
    public mutating func insert(_ text: String) {
        let inserted = Array(text)
        characters.insert(contentsOf: inserted, at: cursorOffset)
        cursorOffset += inserted.count
    }

    /// Deletes the grapheme cluster before the cursor.
    public mutating func backspace() {
        guard cursorOffset > 0 else { return }
        cursorOffset -= 1
        characters.remove(at: cursorOffset)
    }

    /// Deletes the grapheme cluster at the cursor.
    public mutating func delete() {
        guard cursorOffset < characters.count else { return }
        characters.remove(at: cursorOffset)
    }

    /// Moves the cursor one grapheme cluster to the left.
    public mutating func moveCursorLeft() {
        cursorOffset = max(0, cursorOffset - 1)
    }

    /// Moves the cursor one grapheme cluster to the right.
    public mutating func moveCursorRight() {
        cursorOffset = min(characters.count, cursorOffset + 1)
    }

    /// Moves the cursor to the beginning of the buffer.
    public mutating func moveCursorToBeginning() {
        cursorOffset = 0
    }

    /// Moves the cursor to the end of the buffer.
    public mutating func moveCursorToEnd() {
        cursorOffset = characters.count
    }
}
