extension StyledTextRenderer {
    /// Renders a prompt title with a stable visual prefix.
    func titleLine(_ title: StyledText) -> String {
        render("\(StyledText.Segment.accent("◆")) \(StyledText.Segment.primary(title.plainText))")
    }

    /// Renders supporting prompt copy.
    func descriptionLine(_ description: StyledText) -> String {
        render("  \(StyledText.Segment.muted(description.plainText))")
    }

    /// Renders a prompt question with the active filter appended.
    func questionLine(prompt: StyledText, filter: String) -> String {
        var line = render("\(StyledText.Segment.primary(prompt.plainText))")
        if !filter.isEmpty {
            line += " " + render("\(StyledText.Segment.muted("(filter: \(filter))"))")
        }
        return line
    }

    /// Renders an editable text prompt line.
    func inputLine(prompt: StyledText, value: String) -> String {
        "\(render("\(StyledText.Segment.primary(prompt.plainText))")) \(value)"
    }

    /// Renders one selectable option row.
    func optionLine(label: String, focused: Bool, marker: String? = nil) -> String {
        let pointer = focused ? render("\(StyledText.Segment.accent("❯"))") : " "
        let checkbox = marker.map { render("\(StyledText.Segment.accent($0))") + " " } ?? ""
        let renderedLabel = focused ? render("\(StyledText.Segment.primary(label))") : label
        return "\(pointer) \(checkbox)\(renderedLabel)"
    }

    /// Renders a validation error below the active prompt.
    func errorLine(_ message: String) -> String {
        render("\(StyledText.Segment.danger("! \(message)"))")
    }

    /// Renders low-priority keyboard help below an interactive prompt.
    func instructionLine(_ instructions: String) -> String {
        render("  \(StyledText.Segment.muted(instructions))")
    }

    /// Renders the single line a prompt collapses to after being answered.
    func collapsedLine(question: StyledText, answer: String) -> String {
        let status = render("\(StyledText.Segment.success("✓"))")
        let renderedAnswer = render("\(StyledText.Segment.info(answer))")
        return "\(render(question)) \(status) \(renderedAnswer)"
    }
}
