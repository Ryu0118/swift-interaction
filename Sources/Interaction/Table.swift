/// A plain terminal table with headers and rows.
public struct Table: Equatable, Sendable {
    /// Column headers displayed before the rows.
    public let headers: [String]
    /// Row values displayed in table order.
    public let rows: [[String]]

    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }

    public init(@TableBuilder _ content: () -> [TableElement]) {
        var headers: [String] = []
        var rows: [[String]] = []

        for element in content() {
            switch element {
            case let .header(values):
                headers = values
            case let .row(values):
                rows.append(values)
            }
        }

        self.init(headers: headers, rows: rows)
    }
}

/// An element emitted by a table result builder.
public enum TableElement: Equatable, Sendable {
    case header([String])
    case row([String])
}

/// Header cells for a result-builder table declaration.
public struct TableHeader: Equatable, Sendable {
    /// Header cell values.
    public let values: [String]

    public init(_ values: String...) {
        self.values = values
    }

    public init(@TableCellBuilder _ content: () -> [String]) {
        values = content()
    }
}

/// Row cells for a result-builder table declaration.
public struct TableRow: Equatable, Sendable {
    /// Row cell values.
    public let values: [String]

    public init(_ values: String...) {
        self.values = values
    }

    public init(@TableCellBuilder _ content: () -> [String]) {
        values = content()
    }
}

/// Builds a table from header and row declarations.
@resultBuilder
public enum TableBuilder {
    public static func buildBlock(_ components: [TableElement]...) -> [TableElement] {
        components.flatMap(\.self)
    }

    public static func buildExpression(_ expression: TableHeader) -> [TableElement] {
        [.header(expression.values)]
    }

    public static func buildExpression(_ expression: TableRow) -> [TableElement] {
        [.row(expression.values)]
    }

    public static func buildOptional(_ component: [TableElement]?) -> [TableElement] {
        component ?? []
    }

    public static func buildEither(first component: [TableElement]) -> [TableElement] {
        component
    }

    public static func buildEither(second component: [TableElement]) -> [TableElement] {
        component
    }

    public static func buildArray(_ components: [[TableElement]]) -> [TableElement] {
        components.flatMap(\.self)
    }
}

/// Builds the cells inside a table header or row.
@resultBuilder
public enum TableCellBuilder {
    public static func buildBlock(_ components: [String]...) -> [String] {
        components.flatMap(\.self)
    }

    public static func buildExpression(_ expression: String) -> [String] {
        [expression]
    }

    public static func buildExpression(_ expression: StyledText) -> [String] {
        [expression.plainText]
    }

    public static func buildExpression(_ expression: some CustomStringConvertible) -> [String] {
        [expression.description]
    }

    public static func buildOptional(_ component: [String]?) -> [String] {
        component ?? []
    }

    public static func buildEither(first component: [String]) -> [String] {
        component
    }

    public static func buildEither(second component: [String]) -> [String] {
        component
    }

    public static func buildArray(_ components: [[String]]) -> [String] {
        components.flatMap(\.self)
    }
}

/// Renders tables as a bordered box using terminal display widths.
public struct TableRenderer: Sendable {
    private let maximumWidth: Int?

    /// Creates a table renderer, optionally constraining rendered tables to a maximum display width.
    public init(maximumWidth: Int? = nil) {
        self.maximumWidth = maximumWidth
    }

    /// Returns a newline-separated, box-drawn terminal rendering of a table.
    public func render(_ table: Table, maximumWidth overrideMaximumWidth: Int? = nil) -> String {
        let naturalWidths = columnWidths(for: table)
        let columnWidths = constrainedColumnWidths(
            naturalWidths,
            maximumWidth: overrideMaximumWidth ?? maximumWidth,
        )
        guard !columnWidths.isEmpty else { return "" }

        var lines: [String] = [border(columnWidths, left: "┌", mid: "┬", right: "┐")]
        if !table.headers.isEmpty {
            lines.append(contentsOf: row(table.headers, columnWidths: columnWidths))
            lines.append(border(columnWidths, left: "├", mid: "┼", right: "┤"))
        }
        for (index, tableRow) in table.rows.enumerated() {
            if index > 0 {
                lines.append(border(columnWidths, left: "├", mid: "┼", right: "┤"))
            }
            lines.append(contentsOf: row(tableRow, columnWidths: columnWidths))
        }
        lines.append(border(columnWidths, left: "└", mid: "┴", right: "┘"))

        return lines.joined(separator: "\n")
    }

    /// Widest cell (by terminal display width) in each column, across headers and rows.
    private func columnWidths(for table: Table) -> [Int] {
        var allRows = table.rows
        if !table.headers.isEmpty {
            allRows.insert(table.headers, at: 0)
        }
        guard let columnCount = allRows.map(\.count).max(), columnCount > 0 else { return [] }

        var widths = [Int](repeating: 0, count: columnCount)
        for row in allRows {
            for (index, cell) in row.enumerated() {
                widths[index] = max(widths[index], cell.terminalDisplayWidth)
            }
        }
        return widths
    }

    /// Shrinks natural column widths until the whole table fits within `maximumWidth`.
    ///
    /// The calculation reserves the fixed border and padding width first, then
    /// repeatedly trims the widest column so wrapping pressure is spread across
    /// columns instead of collapsing one column immediately.
    private func constrainedColumnWidths(_ naturalWidths: [Int], maximumWidth: Int?) -> [Int] {
        guard let maximumWidth, maximumWidth > 0 else { return naturalWidths }

        let minimumTableWidth = naturalWidths.count * 3 + 1
        let availableCellWidth = maximumWidth - minimumTableWidth
        guard availableCellWidth > 0 else {
            return [Int](repeating: 1, count: naturalWidths.count)
        }

        let naturalCellWidth = naturalWidths.reduce(0, +)
        guard naturalCellWidth > availableCellWidth else { return naturalWidths }

        // Terminates because each iteration either shrinks the widest column by 1
        // or breaks: once every column has hit the width=1 floor, `widths[widestIndex]
        // > 1` fails and the loop exits even if the table still doesn't fit.
        var widths = naturalWidths.map { max($0, 1) }
        while widths.reduce(0, +) > availableCellWidth {
            guard let widestIndex = widths.indices.max(by: { widths[$0] < widths[$1] }),
                  widths[widestIndex] > 1
            else {
                break
            }
            widths[widestIndex] -= 1
        }
        return widths
    }

    /// A horizontal border line, e.g. `┌────┬────┐`.
    private func border(_ columnWidths: [Int], left: String, mid: String, right: String) -> String {
        let segments = columnWidths.map { String(repeating: "─", count: $0 + 2) }
        return left + segments.joined(separator: mid) + right
    }

    /// One or more `│ cell │ cell │` lines, padding wrapped cell fragments.
    private func row(_ row: [String], columnWidths: [Int]) -> [String] {
        let wrappedCells = columnWidths.indices.map { index -> [String] in
            let value = row.indices.contains(index) ? row[index] : ""
            return wrap(value, width: columnWidths[index])
        }
        let lineCount = wrappedCells.map(\.count).max() ?? 1

        return (0 ..< lineCount).map { lineIndex in
            let cells = columnWidths.indices.map { columnIndex -> String in
                let value = wrappedCells[columnIndex].indices.contains(lineIndex) ? wrappedCells[columnIndex][lineIndex] : ""
                let padding = String(repeating: " ", count: columnWidths[columnIndex] - value.terminalDisplayWidth)
                return " " + value + padding + " "
            }
            return "│" + cells.joined(separator: "│") + "│"
        }
    }

    /// Wraps a possibly multi-line cell into display-width-limited fragments.
    ///
    /// Explicit newlines inside the cell are preserved as hard breaks before
    /// applying soft wrapping to each physical line.
    private func wrap(_ value: String, width: Int) -> [String] {
        guard width > 0, !value.isEmpty else { return [""] }

        return value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .flatMap { wrapLine(String($0), width: width) }
    }

    /// Wraps one physical line by words, falling back to grapheme-cluster breaks for oversized words.
    private func wrapLine(_ line: String, width: Int) -> [String] {
        var lines: [String] = []
        var current = ""
        var currentWidth = 0

        func flushCurrent() {
            lines.append(current)
            current = ""
            currentWidth = 0
        }

        for word in words(in: line) {
            let wordWidth = word.terminalDisplayWidth

            if current.isEmpty {
                let chunks = breakWord(word, width: width)
                lines.append(contentsOf: chunks.dropLast())
                current = chunks.last ?? ""
                currentWidth = current.terminalDisplayWidth
                continue
            }

            if currentWidth + 1 + wordWidth <= width {
                current += " " + word
                currentWidth += 1 + wordWidth
                continue
            }

            flushCurrent()

            let chunks = breakWord(word, width: width)
            lines.append(contentsOf: chunks.dropLast())
            current = chunks.last ?? ""
            currentWidth = current.terminalDisplayWidth
        }

        if !current.isEmpty {
            lines.append(current)
        }
        return lines.isEmpty ? [""] : lines
    }

    /// Splits a line into non-empty word tokens, normalizing whitespace runs to a single separator.
    private func words(in line: String) -> [String] {
        line.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    /// Breaks one oversized word into fragments that fit the target display width.
    ///
    /// Iterating by `Character` keeps composed accents, emoji sequences, and CJK
    /// text intact while still respecting terminal display width.
    private func breakWord(_ word: String, width: Int) -> [String] {
        var chunks: [String] = []
        var current = ""
        var currentWidth = 0

        for character in word {
            let characterWidth = character.terminalDisplayWidth
            if currentWidth + characterWidth > width, !current.isEmpty {
                chunks.append(current)
                current = ""
                currentWidth = 0
            }

            current.append(character)
            currentWidth += characterWidth

            if currentWidth >= width {
                chunks.append(current)
                current = ""
                currentWidth = 0
            }
        }

        if !current.isEmpty {
            chunks.append(current)
        }
        return chunks.isEmpty ? [""] : chunks
    }
}
