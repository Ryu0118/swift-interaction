/// Interactive single-key loop for yes/no confirmation prompts.
struct ConfirmationLoop {
    private let prompt: ConfirmationPrompt
    private let styleRenderer: StyledTextRenderer
    private var block: BlockRenderer

    init(prompt: ConfirmationPrompt, output: any TextOutput, styleRenderer: StyledTextRenderer) {
        self.prompt = prompt
        self.styleRenderer = styleRenderer
        block = BlockRenderer(output: output)
    }

    mutating func run(keys: any KeyInput) -> InteractiveOutcome<Bool> {
        render()

        while true {
            guard let key = keys.readKey() else { return .inputClosed }
            switch key {
            case .interrupt:
                return .interrupted
            case .endOfInput:
                return .inputClosed
            case .character("y"), .character("Y"):
                finish(with: true)
                return .answered(true)
            case .character("n"), .character("N"):
                finish(with: false)
                return .answered(false)
            case .enter:
                finish(with: prompt.defaultAnswer)
                return .answered(prompt.defaultAnswer)
            default:
                break
            }
        }
    }

    private var questionLine: String {
        let suffix = prompt.defaultAnswer ? "[Y/n]" : "[y/N]"
        return "\(styleRenderer.questionLine(prompt: prompt.question, filter: "")) \(styleRenderer.render("\(StyledText.Segment.muted(suffix))"))"
    }

    private mutating func render() {
        var lines: [String] = []
        if let title = prompt.title {
            lines.append(styleRenderer.titleLine(title))
        }
        if let description = prompt.description {
            lines.append(styleRenderer.descriptionLine(description))
        }
        lines.append(questionLine)

        let cursorLine = lines.count - 1
        let column = lines[cursorLine].terminalDisplayWidth + 1
        block.render(lines, cursor: (line: cursorLine, column: column))
    }

    private mutating func finish(with answer: Bool) {
        guard prompt.collapsesOnAnswer else {
            block.render([questionLine + " " + (answer ? "yes" : "no")])
            return
        }
        block.clear()
        block.render([styleRenderer.collapsedLine(question: prompt.question, answer: answer ? "yes" : "no")])
    }
}
