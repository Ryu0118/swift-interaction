import Foundation

/// Selection state for a single-choice prompt.
public struct SingleSelectionState<Value: Equatable & CustomStringConvertible & Sendable>: Equatable, Sendable {
    /// All available options before filtering.
    public let options: [ChoiceOption<Value>]

    /// The focused cursor index within `visibleOptions`.
    public private(set) var cursorIndex: Int
    /// The current case-insensitive filter text.
    public var filter: String {
        didSet { clampCursor() }
    }

    public init(options: [ChoiceOption<Value>], filter: String = "", cursorIndex: Int = 0) {
        self.options = options
        self.filter = filter
        self.cursorIndex = cursorIndex
        clampCursor()
    }

    /// Options matching the current filter.
    public var visibleOptions: [ChoiceOption<Value>] {
        guard !filter.isEmpty else { return options }
        return options.filter { option in
            option.label.localizedStandardContains(filter)
        }
    }

    /// The currently focused option, if any.
    public var selected: ChoiceOption<Value>? {
        guard visibleOptions.indices.contains(cursorIndex) else { return nil }
        return visibleOptions[cursorIndex]
    }

    /// Moves focus to the previous visible option, wrapping at the beginning.
    public mutating func moveUp() {
        guard !visibleOptions.isEmpty else { return }
        cursorIndex = cursorIndex == 0 ? visibleOptions.count - 1 : cursorIndex - 1
    }

    /// Moves focus to the next visible option, wrapping at the end.
    public mutating func moveDown() {
        guard !visibleOptions.isEmpty else { return }
        cursorIndex = (cursorIndex + 1) % visibleOptions.count
    }

    /// Moves focus to the first visible option.
    public mutating func moveCursorToBeginning() {
        cursorIndex = 0
    }

    mutating func clampCursor() {
        guard !visibleOptions.isEmpty else {
            cursorIndex = 0
            return
        }
        cursorIndex = min(max(cursorIndex, 0), visibleOptions.count - 1)
    }
}
