/// Interactive arrow-key loop for multiple-choice prompts.
struct MultipleChoiceLoop<Option: Equatable & CustomStringConvertible & Sendable> {
    private let prompt: MultipleChoicePrompt<Option>
    private let styleRenderer: StyledTextRenderer
    private var state: MultipleSelectionState<Option>
    private var block: BlockRenderer
    private var validationMessage: String?

    init(prompt: MultipleChoicePrompt<Option>, output: any TextOutput, styleRenderer: StyledTextRenderer) {
        self.prompt = prompt
        self.styleRenderer = styleRenderer
        state = MultipleSelectionState(
            options: prompt.options.map { ChoiceOption($0) },
            minimumSelectionCount: prompt.minimumSelectionCount,
            maximumSelectionCount: prompt.maximumSelectionCount,
        )
        block = BlockRenderer(output: output)
    }

    mutating func run(keys: any KeyInput) -> InteractiveOutcome<[Option]> {
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
            case .character(" "):
                state.toggleFocusedOption()
                validationMessage = nil
            case .backspace:
                if prompt.allowsFiltering {
                    state.filter = String(state.filter.dropLast())
                }
            case let .character(character):
                if prompt.allowsFiltering, !character.isNewline {
                    state.filter.append(character)
                }
            case .enter:
                if state.selectedValues.count >= prompt.minimumSelectionCount {
                    finish()
                    return .answered(state.selectedValues)
                }
                validationMessage = "Select at least \(prompt.minimumSelectionCount) option(s)."
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
        let selected = state.selectedValues
        if visible.isEmpty {
            lines.append(styleRenderer.render("  \(StyledText.Segment.muted("(no matches)"))"))
        }
        for (index, option) in visible.enumerated() {
            let marker = selected.contains(option.value) ? "●" : "○"
            lines.append(styleRenderer.optionLine(label: option.label, focused: index == state.cursorIndex, marker: marker))
        }

        if let validationMessage {
            lines.append(styleRenderer.errorLine(validationMessage))
        }
        lines.append(styleRenderer.instructionLine(instructions))
        return lines
    }

    private var instructions: String {
        var parts = ["↑/↓ move", "space toggle", "enter confirm"]
        if prompt.allowsFiltering {
            parts.insert("type to filter", at: 1)
        }
        return parts.joined(separator: " · ")
    }

    private mutating func finish() {
        guard prompt.collapsesOnSelection else {
            block.render(lines())
            return
        }
        block.clear()
        let answer = state.selectedValues.map(\.description).joined(separator: ", ")
        block.render([styleRenderer.collapsedLine(question: prompt.question, answer: answer)])
    }
}
