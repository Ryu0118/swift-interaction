import Foundation

/// Validates a text prompt answer.
public protocol ValidationRule: Sendable {
    /// Returns a validation error when the input is invalid.
    func validate(_ input: String) -> ValidationError?
}

/// A validation rule defined by a pass/fail predicate and a fixed error.
public protocol PredicateValidationRule: ValidationRule {
    /// The error reported when the predicate fails.
    var error: ValidationError { get }
    /// Returns whether the input passes the rule.
    func validate(input: String) -> Bool
}

public extension PredicateValidationRule {
    /// Returns the fixed error when the predicate fails.
    func validate(_ input: String) -> ValidationError? {
        validate(input: input) ? nil : error
    }
}

/// A user-facing validation failure.
public struct ValidationError: LocalizedError, Equatable, Sendable {
    /// The validation message to display.
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? {
        message
    }
}

/// Requires non-empty text input.
public struct NonEmptyRule: ValidationRule {
    private let message: String

    public init(message: String = "Input cannot be empty.") {
        self.message = message
    }

    /// Validates that the input is not empty.
    public func validate(_ input: String) -> ValidationError? {
        input.isEmpty ? ValidationError(message) : nil
    }
}

public extension Collection<any ValidationRule> {
    func validate(_ input: String) -> [ValidationError] {
        compactMap { $0.validate(input) }
    }
}
