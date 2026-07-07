import Foundation

/// A key event read from the terminal.
public enum TerminalKey: Equatable, Sendable {
    /// A printable character, including space.
    case character(Character)
    /// The up arrow key.
    case up
    /// The down arrow key.
    case down
    /// The left arrow key.
    case left
    /// The right arrow key.
    case right
    /// The return or enter key.
    case enter
    /// The backspace key.
    case backspace
    /// The forward-delete key.
    case delete
    /// Ctrl-C.
    case interrupt
    /// Ctrl-D.
    case endOfInput
}

/// Reads key events for interactive prompts.
public protocol KeyInput: Sendable {
    /// Reads the next key event, or nil when input is exhausted.
    func readKey() -> TerminalKey?
    /// Runs the body with the input source in raw mode when supported.
    func withRawInput<Result>(_ body: () throws -> Result) rethrows -> Result
    /// Runs the asynchronous body with the input source in raw mode when supported.
    func withRawInput<Result>(_ body: () async throws -> Result) async rethrows -> Result
}

public extension KeyInput {
    /// Runs the body without changing any terminal modes.
    func withRawInput<Result>(_ body: () throws -> Result) rethrows -> Result {
        try body()
    }

    /// Runs the asynchronous body without changing any terminal modes.
    func withRawInput<Result>(_ body: () async throws -> Result) async rethrows -> Result {
        try await body()
    }
}
