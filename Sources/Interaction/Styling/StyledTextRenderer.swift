/// Renders styled text into terminal-ready strings.
public struct StyledTextRenderer: Sendable {
    /// Whether ANSI color codes are emitted around styled segments.
    public let colorized: Bool

    public init(colorized: Bool) {
        self.colorized = colorized
    }

    /// Returns the rendered representation of the styled text.
    public func render(_ text: StyledText) -> String {
        guard colorized else { return text.plainText }
        return text.segments.map(render(segment:)).joined()
    }

    private func render(segment: StyledText.Segment) -> String {
        guard let code = segment.ansiCode else { return segment.plainValue }
        return "\u{1B}[\(code)m\(segment.plainValue)\u{1B}[0m"
    }
}

private extension StyledText.Segment {
    var ansiCode: String? {
        switch self {
        case .plain, .secondary:
            nil
        case .command:
            "36"
        case .path:
            "36"
        case .link:
            "4;34"
        case .primary:
            "1"
        case .muted:
            "2"
        case .accent:
            "33"
        case .danger:
            "31"
        case .success:
            "32"
        case .info:
            "34"
        }
    }
}
