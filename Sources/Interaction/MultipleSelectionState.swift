/// Selection state for a multiple-choice prompt.
public struct MultipleSelectionState<Value: Equatable & CustomStringConvertible & Sendable>: Equatable, Sendable {
    /// The minimum number of values the user must select.
    public let minimumSelectionCount: Int
    /// The maximum number of values the user may select.
    public let maximumSelectionCount: Int?

    private var cursor: SingleSelectionState<Value>
    private var selectedIndexes: Set<Int>

    /// All available options before filtering.
    public var options: [ChoiceOption<Value>] {
        cursor.options
    }

    /// The focused cursor index within `visibleOptions`.
    public var cursorIndex: Int {
        cursor.cursorIndex
    }

    /// The current case-insensitive filter text.
    public var filter: String {
        get { cursor.filter }
        set { cursor.filter = newValue }
    }

    public init(
        options: [ChoiceOption<Value>],
        minimumSelectionCount: Int = 0,
        maximumSelectionCount: Int? = nil,
    ) {
        cursor = SingleSelectionState(options: options)
        self.minimumSelectionCount = minimumSelectionCount
        self.maximumSelectionCount = maximumSelectionCount
        selectedIndexes = []
    }

    /// Options matching the current filter.
    public var visibleOptions: [ChoiceOption<Value>] {
        cursor.visibleOptions
    }

    /// Values selected in their original option order.
    public var selectedValues: [Value] {
        selectedIndexes.sorted().map { options[$0].value }
    }

    /// Moves focus to the previous visible option, wrapping at the beginning.
    public mutating func moveUp() {
        cursor.moveUp()
    }

    /// Moves focus to the next visible option, wrapping at the end.
    public mutating func moveDown() {
        cursor.moveDown()
    }

    /// Moves focus to the first visible option.
    public mutating func moveCursorToBeginning() {
        cursor.moveCursorToBeginning()
    }

    /// Toggles the focused option while respecting selection bounds.
    public mutating func toggleFocusedOption() {
        guard let focused = visibleOptions[safe: cursorIndex],
              let originalIndex = options.firstIndex(of: focused) else { return }

        if selectedIndexes.contains(originalIndex) {
            guard selectedIndexes.count > minimumSelectionCount else { return }
            selectedIndexes.remove(originalIndex)
        } else {
            if let maximumSelectionCount, selectedIndexes.count >= maximumSelectionCount {
                return
            }
            selectedIndexes.insert(originalIndex)
        }
    }
}
