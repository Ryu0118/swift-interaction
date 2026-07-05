import Foundation

/// Interface for terminal interaction used by command runners.
public protocol InteractionProviding: Sendable {
    /// Writes styled text without adding a status prefix.
    func write(_ text: StyledText)
    /// Writes a status-prefixed message.
    func writeStatus(_ status: Status, _ message: StyledText)
    /// Writes a rendered table.
    func writeTable(_ table: Table)
    /// Reads a text answer from the user.
    func readText(_ prompt: TextPrompt) -> String
    /// Reads a yes/no answer from the user.
    func confirm(_ prompt: ConfirmationPrompt) -> Bool
    /// Reads one choice from the user.
    func choose<Option>(_ prompt: ChoicePrompt<Option>) -> Option
    /// Reads multiple choices from the user.
    func chooseMany<Option>(_ prompt: MultipleChoicePrompt<Option>) -> [Option]
}

/// Status categories for terminal messages.
public enum Status: Sendable {
    case success
    case failure
    case warning
    case info
}

/// Default terminal interaction implementation.
public struct Terminal: InteractionProviding {
    let input: any TextInput
    let keyInput: any KeyInput
    let output: any TextOutput
    let tableRenderer: TableRenderer
    let capabilities: TerminalCapabilities
    let styleRenderer: StyledTextRenderer

    public init(
        input: some TextInput = StandardInput(),
        keyInput: some KeyInput = StandardKeyInput(),
        output: some TextOutput = StandardOutput(),
        tableRenderer: TableRenderer = TableRenderer(),
        capabilities: TerminalCapabilities = .detect(),
    ) {
        self.input = input
        self.keyInput = keyInput
        self.output = output
        self.tableRenderer = tableRenderer
        self.capabilities = capabilities
        styleRenderer = StyledTextRenderer(colorized: capabilities.supportsColor)
    }

    /// Writes styled text to the terminal.
    public func write(_ text: StyledText) {
        output.write(styleRenderer.render(text))
    }

    /// Writes a status-prefixed message.
    public func writeStatus(_ status: Status, _ message: StyledText) {
        output.write("\(styleRenderer.render(status.styledPrefix)) \(styleRenderer.render(message))\n")
    }

    /// Writes a rendered table followed by a newline.
    public func writeTable(_ table: Table) {
        output.write(tableRenderer.render(table, maximumWidth: capabilities.width) + "\n")
    }

    /// Prompts until the user enters text that passes validation.
    public func readText(_ prompt: TextPrompt) -> String {
        guard capabilities.isInteractive else {
            return readTextByLine(prompt)
        }
        return resolve(keyInput.withRawInput {
            var loop = TextPromptLoop(prompt: prompt, output: output, styleRenderer: styleRenderer)
            return loop.run(keys: keyInput)
        })
    }

    /// Prompts for a yes/no answer.
    public func confirm(_ prompt: ConfirmationPrompt) -> Bool {
        guard capabilities.isInteractive else {
            return confirmByLine(prompt)
        }
        return resolve(keyInput.withRawInput {
            var loop = ConfirmationLoop(prompt: prompt, output: output, styleRenderer: styleRenderer)
            return loop.run(keys: keyInput)
        })
    }

    /// Prompts for one option.
    public func choose<Option>(_ prompt: ChoicePrompt<Option>) -> Option {
        precondition(!prompt.options.isEmpty, "Choice prompts require at least one option.")
        if prompt.options.count == 1, prompt.automaticallySelectsSingleOption {
            return prompt.options[0]
        }
        guard capabilities.isInteractive else {
            return chooseByNumber(prompt)
        }
        return resolve(withHiddenCursor {
            keyInput.withRawInput {
                var loop = SingleChoiceLoop(prompt: prompt, output: output, styleRenderer: styleRenderer)
                return loop.run(keys: keyInput)
            }
        })
    }

    /// Prompts for multiple options.
    public func chooseMany<Option>(_ prompt: MultipleChoicePrompt<Option>) -> [Option] {
        precondition(!prompt.options.isEmpty, "Multiple-choice prompts require at least one option.")
        guard capabilities.isInteractive else {
            return chooseManyByNumber(prompt)
        }
        return resolve(withHiddenCursor {
            keyInput.withRawInput {
                var loop = MultipleChoiceLoop(prompt: prompt, output: output, styleRenderer: styleRenderer)
                return loop.run(keys: keyInput)
            }
        })
    }

    private func resolve<Value>(_ outcome: InteractiveOutcome<Value>) -> Value {
        switch outcome {
        case let .answered(value):
            return value
        case .interrupted:
            output.write("\n")
            exit(130)
        case .inputClosed:
            // Standard input is exhausted: answering with a default here would
            // silently approve security-sensitive confirmations, so fail closed.
            FileHandle.standardError.write(Data("[error] Standard input closed before the prompt was answered.\n".utf8))
            exit(EXIT_FAILURE)
        }
    }

    private func withHiddenCursor<Value>(_ body: () -> InteractiveOutcome<Value>) -> InteractiveOutcome<Value> {
        output.write("\u{1B}[?25l")
        defer { output.write("\u{1B}[?25h") }
        return body()
    }
}

/// Reads text from an input source.
public protocol TextInput: Sendable {
    /// Reads one line of text.
    func readLine() -> String?
}

/// Writes text to an output sink.
public protocol TextOutput: Sendable {
    /// Writes text without adding extra formatting.
    func write(_ text: String)
}

/// Standard input backed by `Swift.readLine`.
public struct StandardInput: TextInput {
    public init() {}

    /// Reads one line from standard input.
    public func readLine() -> String? {
        Swift.readLine(strippingNewline: true)
    }
}

/// Standard output backed by `FileHandle.standardOutput`.
public struct StandardOutput: TextOutput {
    public init() {}

    /// Writes text to standard output.
    public func write(_ text: String) {
        FileHandle.standardOutput.write(Data(text.utf8))
    }
}

private extension Status {
    var styledPrefix: StyledText {
        switch self {
        case .success:
            "\(StyledText.Segment.success("[success]"))"
        case .failure:
            "\(StyledText.Segment.danger("[error]"))"
        case .warning:
            "\(StyledText.Segment.accent("[warning]"))"
        case .info:
            "\(StyledText.Segment.info("[info]"))"
        }
    }
}
