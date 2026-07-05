/// Text that carries lightweight semantic styling for terminal output.
public struct StyledText: ExpressibleByStringInterpolation, Equatable, Hashable, Sendable {
    /// A styled segment inside a terminal message.
    public enum Segment: Equatable, Hashable, Sendable {
        case plain(String)
        case command(String)
        case path(String)
        case link(title: String, destination: String)
        case primary(String)
        case secondary(String)
        case muted(String)
        case accent(String)
        case danger(String)
        case success(String)
        case info(String)
    }

    /// The ordered segments that make up the text.
    public let segments: [Segment]

    public init(_ value: String) {
        segments = [.plain(value)]
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(stringInterpolation: StringInterpolation) {
        segments = stringInterpolation.segments
    }

    /// The message rendered without semantic styling.
    public var plainText: String {
        segments.map(\.plainValue).joined()
    }

    /// String interpolation storage for styled terminal messages.
    public struct StringInterpolation: StringInterpolationProtocol {
        var segments: [Segment] = []

        public init(literalCapacity _: Int, interpolationCount _: Int) {}

        public mutating func appendLiteral(_ literal: String) {
            segments.append(.plain(literal))
        }

        public mutating func appendInterpolation(_ value: some Any) {
            segments.append(.plain(String(describing: value)))
        }

        public mutating func appendInterpolation(_ segment: Segment) {
            segments.append(segment)
        }

        public mutating func appendInterpolation(_ text: StyledText) {
            segments.append(contentsOf: text.segments)
        }
    }
}

package extension StyledText.Segment {
    /// The segment's text without any styling applied.
    var plainValue: String {
        switch self {
        case let .plain(value),
             let .primary(value),
             let .secondary(value),
             let .muted(value),
             let .accent(value),
             let .danger(value),
             let .success(value),
             let .info(value):
            value
        case let .command(value):
            "'\(value)'"
        case let .path(value):
            value
        case let .link(title, destination):
            "<\(title): \(destination)>"
        }
    }
}
