public extension InteractionProviding {
    /// Writes styled text as an indented line.
    func writeLine(_ text: StyledText = "", tab: UInt = 0, indentSpace: UInt = 4) {
        let indent = String(repeating: " ", count: Int(tab * indentSpace))
        write("\(indent)\(text)\n")
    }

    /// Writes a success-prefixed message.
    func writeSuccess(_ message: StyledText) {
        writeStatus(.success, message)
    }

    /// Writes a failure-prefixed message.
    func writeFailure(_ message: StyledText) {
        writeStatus(.failure, message)
    }

    /// Writes an info-prefixed message.
    func writeInfo(_ message: StyledText) {
        writeStatus(.info, message)
    }

    /// Writes a warning-prefixed message.
    func writeWarning(_ message: StyledText) {
        writeStatus(.warning, message)
    }
}
