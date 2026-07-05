/// Interactive line-editing loop for text prompts.
struct TextPromptLoop {
    private let prompt: TextPrompt
    private let styleRenderer: StyledTextRenderer
    private var buffer = LineBuffer()
    private var errors: [ValidationError] = []
    private var block: BlockRenderer

    init(prompt: TextPrompt, output: any TextOutput, styleRenderer: StyledTextRenderer) {
        self.prompt = prompt
        self.styleRenderer = styleRenderer
        block = BlockRenderer(output: output)
    }

    mutating func run(keys: any KeyInput) -> InteractiveOutcome<String> {
        render()

        while true {
            guard let key = keys.readKey() else { return .inputClosed }
            switch key {
            case .interrupt:
                return .interrupted
            case .endOfInput:
                return .inputClosed
            case let .character(character):
                if !character.isNewline {
                    buffer.insert(String(character))
                    errors = []
                }
            case .backspace:
                buffer.backspace()
            case .delete:
                buffer.delete()
            case .left:
                buffer.moveCursorLeft()
            case .right:
                buffer.moveCursorRight()
            case .up, .down:
                break
            case .enter:
                errors = prompt.validationRules.validate(buffer.text)
                if errors.isEmpty {
                    finish()
                    return .answered(buffer.text)
                }
            }
            render()
        }
    }

    private var messagePrefix: String {
        styleRenderer.inputLine(prompt: prompt.message, value: "")
    }

    private mutating func render() {
        var lines: [String] = []
        if let title = prompt.title {
            lines.append(styleRenderer.titleLine(title))
        }
        if let description = prompt.description {
            lines.append(styleRenderer.descriptionLine(description))
        }

        let messageLine = lines.count
        lines.append(messagePrefix + buffer.text)
        lines.append(contentsOf: errors.map { error in
            styleRenderer.errorLine(error.message)
        })

        let column = messagePrefix.terminalDisplayWidth + buffer.cursorDisplayColumn
        block.render(lines, cursor: (line: messageLine, column: column))
    }

    private mutating func finish() {
        guard prompt.collapsesOnAnswer else {
            block.render([messagePrefix + buffer.text])
            return
        }
        block.clear()
        block.render([styleRenderer.collapsedLine(question: prompt.message, answer: buffer.text)])
    }
}
