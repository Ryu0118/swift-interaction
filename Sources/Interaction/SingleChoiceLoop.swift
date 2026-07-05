/// Interactive arrow-key loop for single-choice prompts.
struct SingleChoiceLoop<Option: Equatable & CustomStringConvertible & Sendable> {
    private let prompt: ChoicePrompt<Option>
    private let styleRenderer: StyledTextRenderer
    private var state: SingleSelectionState<Option>
    private var block: BlockRenderer

    init(prompt: ChoicePrompt<Option>, output: any TextOutput, styleRenderer: StyledTextRenderer) {
        self.prompt = prompt
        self.styleRenderer = styleRenderer
        state = SingleSelectionState(options: prompt.options.map { ChoiceOption($0) })
        block = BlockRenderer(output: output)
    }

    mutating func run(keys: any KeyInput) -> InteractiveOutcome<Option> {
        block.render(lines())

        while true {
            guard let key = keys.readKey() else { return .inputClosed }
            switch key {
            case .interrupt:
                return .interrupted
            case .endOfInput:
                return .inputClosed
            case .up:
                state.moveUp()
            case .down:
                state.moveDown()
            case .backspace:
                if prompt.allowsFiltering {
                    state.filter = String(state.filter.dropLast())
                }
            case let .character(character):
                if prompt.allowsFiltering, !character.isNewline {
                    state.filter.append(character)
                }
            case .enter:
                if let selected = state.selected {
                    finish(with: selected)
                    return .answered(selected.value)
                }
            case .left, .right, .delete:
                break
            }
            block.render(lines())
        }
    }

    private func lines() -> [String] {
        var lines: [String] = []
        if let title = prompt.title {
            lines.append(styleRenderer.titleLine(title))
        }
        lines.append(styleRenderer.questionLine(prompt: prompt.question, filter: state.filter))
        if let description = prompt.description {
            lines.append(styleRenderer.descriptionLine(description))
        }

        let visible = state.visibleOptions
        if visible.isEmpty {
            lines.append(styleRenderer.render("  \(StyledText.Segment.muted("(no matches)"))"))
        }
        for (index, option) in visible.enumerated() {
            lines.append(styleRenderer.optionLine(label: option.label, focused: index == state.cursorIndex))
        }

        lines.append(styleRenderer.instructionLine(instructions))
        return lines
    }

    private var instructions: String {
        prompt.allowsFiltering ? "↑/↓ move · type to filter · enter select" : "↑/↓ move · enter select"
    }

    private mutating func finish(with option: ChoiceOption<Option>) {
        guard prompt.collapsesOnSelection else {
            block.render(lines())
            return
        }
        block.clear()
        block.render([styleRenderer.collapsedLine(question: prompt.question, answer: option.label)])
    }
}
