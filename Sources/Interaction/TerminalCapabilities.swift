import Foundation

/// Capabilities of the terminal session attached to the current process.
public struct TerminalCapabilities: Equatable, Sendable {
    /// Whether prompts can use raw-mode interactive input.
    public let isInteractive: Bool
    /// Whether ANSI color codes should be emitted.
    public let supportsColor: Bool
    /// The current terminal width in display columns, when it can be detected.
    public let width: Int?

    /// Creates a terminal capability snapshot.
    public init(isInteractive: Bool, supportsColor: Bool, width: Int? = nil) {
        self.isInteractive = isInteractive
        self.supportsColor = supportsColor
        self.width = width
    }

    /// Capabilities detected from the standard streams and environment.
    public static func detect(environment: [String: String] = ProcessInfo.processInfo.environment) -> TerminalCapabilities {
        let stdinIsTTY = isatty(STDIN_FILENO) == 1
        let stdoutIsTTY = isatty(STDOUT_FILENO) == 1
        let isDumb = environment["TERM"] == "dumb"
        let noColor = environment["NO_COLOR"].map { !$0.isEmpty } ?? false

        return TerminalCapabilities(
            isInteractive: stdinIsTTY && stdoutIsTTY && !isDumb,
            supportsColor: stdoutIsTTY && !isDumb && !noColor,
            width: detectedWidth(environment: environment, stdoutIsTTY: stdoutIsTTY),
        )
    }

    /// Returns the terminal width from `COLUMNS` or, for TTY output, the terminal window size.
    private static func detectedWidth(environment: [String: String], stdoutIsTTY: Bool) -> Int? {
        if let columns = environment["COLUMNS"].flatMap(Int.init), columns > 0 {
            return columns
        }

        guard stdoutIsTTY else { return nil }

        var size = winsize()
        let result = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size)
        guard result == 0, size.ws_col > 0 else { return nil }
        return Int(size.ws_col)
    }
}
