import Foundation

/// Key input backed by the standard input file descriptor.
public struct StandardKeyInput: KeyInput {
    public init() {}

    /// Reads and decodes the next key from standard input.
    public func readKey() -> TerminalKey? {
        guard let byte = readByte() else { return nil }
        return switch byte {
        case 0x03: .interrupt
        case 0x04: .endOfInput
        case 0x0A, 0x0D: .enter
        case 0x7F, 0x08: .backspace
        case 0x1B: readEscapeSequence()
        default: readCharacter(startingWith: byte)
        }
    }

    /// Puts the terminal into raw input mode for the duration of the body.
    public func withRawInput<Result>(_ body: () throws -> Result) rethrows -> Result {
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            return try body()
        }

        var raw = original
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG)
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        defer { tcsetattr(STDIN_FILENO, TCSANOW, &original) }
        return try body()
    }

    /// Puts the terminal into raw input mode for the duration of the asynchronous body.
    public func withRawInput<Result>(_ body: () async throws -> Result) async rethrows -> Result {
        var original = termios()
        guard tcgetattr(STDIN_FILENO, &original) == 0 else {
            return try await body()
        }

        var raw = original
        raw.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG)
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        defer { tcsetattr(STDIN_FILENO, TCSANOW, &original) }
        return try await body()
    }

    private func readByte() -> UInt8? {
        var byte: UInt8 = 0
        let count = read(STDIN_FILENO, &byte, 1)
        return count == 1 ? byte : nil
    }

    /// Decodes an ANSI CSI sequence (`ESC [ <final byte>`) for the arrow and
    /// delete keys. A lone ESC not followed by `[`, or a `[` followed by an
    /// unrecognized final byte, is treated as the start of the *next* key
    /// rather than reported as-is, since bare ESC has no `TerminalKey` case.
    /// Delete is `ESC [ 3 ~`; the trailing `~` byte is read and discarded.
    private func readEscapeSequence() -> TerminalKey? {
        guard readByte() == UInt8(ascii: "[") else {
            return readKey()
        }
        switch readByte() {
        case UInt8(ascii: "A"): return .up
        case UInt8(ascii: "B"): return .down
        case UInt8(ascii: "C"): return .right
        case UInt8(ascii: "D"): return .left
        case UInt8(ascii: "3"):
            _ = readByte()
            return .delete
        default:
            return readKey()
        }
    }

    private func readCharacter(startingWith first: UInt8) -> TerminalKey? {
        var bytes = [first]
        for _ in 0 ..< first.utf8ContinuationCount {
            guard let next = readByte() else { return nil }
            bytes.append(next)
        }

        guard let decoded = String(bytes: bytes, encoding: .utf8),
              let character = decoded.first
        else {
            return readKey()
        }
        return .character(character)
    }
}

private extension UInt8 {
    /// Number of additional UTF-8 continuation bytes that follow this byte
    /// when it is a multi-byte lead byte, per the UTF-8 byte-length ranges
    /// (0xC0-0xDF: 2-byte sequence, 0xE0-0xEF: 3-byte, 0xF0-0xF7: 4-byte).
    /// Zero for single-byte ASCII and for stray continuation/invalid bytes.
    var utf8ContinuationCount: Int {
        switch self {
        case 0xC0 ... 0xDF: 1
        case 0xE0 ... 0xEF: 2
        case 0xF0 ... 0xF7: 3
        default: 0
        }
    }
}
