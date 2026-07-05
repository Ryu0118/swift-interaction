import Foundation

/// A selectable option with a display label.
public struct ChoiceOption<Value: Equatable & CustomStringConvertible & Sendable>: Equatable, Sendable {
    /// The value returned when the option is selected.
    public let value: Value
    /// The label shown to the user.
    public let label: String

    public init(_ value: Value, label: String? = nil) {
        self.value = value
        self.label = label ?? value.description
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
