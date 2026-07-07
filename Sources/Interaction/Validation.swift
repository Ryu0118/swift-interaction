import Foundation

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

/// A composable rule for validating text prompt input.
///
/// Construct one from a closure that inspects the input and returns the
/// error to display, or `nil` when the input is valid:
///
/// ```swift
/// let maxLength = ValidationRule { input in
///     input.count <= 40 ? nil : ValidationError("Must be 40 characters or fewer.")
/// }
/// ```
///
/// A rule's closure may be asynchronous, which makes it possible to validate
/// against the filesystem or another external source:
///
/// ```swift
/// let fileExists = ValidationRule { input in
///     await FileManager.default.fileExists(atPath: input)
///         ? nil : ValidationError("No file exists at that path.")
/// }
/// ```
public struct ValidationRule: Sendable {
    private let validate: @Sendable (String) async -> ValidationError?

    /// Creates a rule from a closure that returns the failure error, if any.
    public init(_ validate: @escaping @Sendable (String) async -> ValidationError?) {
        self.validate = validate
    }

    /// Runs the rule against `input`, returning its failure error, if any.
    public func callAsFunction(_ input: String) async -> ValidationError? {
        await validate(input)
    }
}

public extension ValidationRule {
    /// Requires non-empty text input.
    static func nonEmpty(message: String = "Input cannot be empty.") -> ValidationRule {
        ValidationRule { input in
            input.isEmpty ? ValidationError(message) : nil
        }
    }
}

public extension Sequence<ValidationRule> {
    /// Runs every rule against `input`, collecting every failure instead of stopping at the first one.
    func validate(_ input: String) async -> [ValidationError] {
        var errors: [ValidationError] = []
        for rule in self {
            if let error = await rule(input) {
                errors.append(error)
            }
        }
        return errors
    }
}
