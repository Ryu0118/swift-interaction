import Foundation

/// Non-interactive fallback rendering used when the terminal isn't a TTY
/// (e.g. piped input/output, CI logs): plain `readLine()`-based prompts
/// instead of the raw-mode, redrawing interactive loops.
extension Terminal {
    func readTextByLine(_ prompt: TextPrompt) -> String {
        while true {
            renderTitle(prompt.title)
            output.write("\(styleRenderer.render(prompt.message)) ")

            let answer = readLineOrAbort()
            let errors = prompt.validationRules.validate(answer)
            guard errors.isEmpty else {
                for error in errors {
                    writeStatus(.failure, "\(error.message)")
                }
                continue
            }
            return answer
        }
    }

    func confirmByLine(_ prompt: ConfirmationPrompt) -> Bool {
        renderTitle(prompt.title)
        let suffix = prompt.defaultAnswer ? "[Y/n]" : "[y/N]"
        output.write("\(styleRenderer.render(prompt.question)) \(suffix) ")

        let answer = readLineOrAbort().trimmingCharacters(in: .whitespacesAndNewlines)
        if answer.isEmpty {
            return prompt.defaultAnswer
        }
        return ["y", "yes"].contains(answer.lowercased())
    }

    func chooseByNumber<Option>(_ prompt: ChoicePrompt<Option>) -> Option {
        renderOptionList(title: prompt.title, question: prompt.question, options: prompt.options)

        while true {
            output.write("> ")
            guard let index = Int(readLineOrAbort().trimmingCharacters(in: .whitespacesAndNewlines)),
                  prompt.options.indices.contains(index - 1)
            else {
                writeStatus(.failure, "Enter a number from 1 to \(prompt.options.count).")
                continue
            }
            return prompt.options[index - 1]
        }
    }

    func chooseManyByNumber<Option>(_ prompt: MultipleChoicePrompt<Option>) -> [Option] {
        renderOptionList(title: prompt.title, question: prompt.question, options: prompt.options)

        while true {
            output.write("> ")
            let indexes = parseIndexes(readLineOrAbort(), optionCount: prompt.options.count)
            if indexes.count < prompt.minimumSelectionCount {
                writeStatus(.failure, "Select at least \(prompt.minimumSelectionCount) option(s).")
                continue
            }
            if let maximumSelectionCount = prompt.maximumSelectionCount, indexes.count > maximumSelectionCount {
                writeStatus(.failure, "Select at most \(maximumSelectionCount) option(s).")
                continue
            }
            return indexes.map { prompt.options[$0] }
        }
    }

    func readLineOrAbort() -> String {
        guard let line = input.readLine() else {
            // Standard input is exhausted: answering with a default here would
            // silently approve security-sensitive confirmations, so fail closed.
            FileHandle.standardError.write(Data("[error] Standard input closed before the prompt was answered.\n".utf8))
            exit(EXIT_FAILURE)
        }
        return line
    }

    func renderTitle(_ title: StyledText?) {
        guard let title else { return }
        output.write("\(styleRenderer.render(title))\n")
    }

    func renderOptionList(title: StyledText?, question: StyledText, options: [some CustomStringConvertible]) {
        var text = title.map { "\(styleRenderer.render($0))\n" } ?? ""
        text += "\(styleRenderer.render(question))\n"
        for (index, option) in options.enumerated() {
            text += "  \(index + 1). \(option.description)\n"
        }
        output.write(text)
    }

    /// Parses a comma/space-separated list of 1-based option numbers.
    ///
    /// Duplicate numbers collapse to one selection, and any token that fails
    /// to parse or falls outside the valid range is silently dropped rather
    /// than rejecting the whole line — the resulting count is then checked
    /// against `minimumSelectionCount`/`maximumSelectionCount` by the caller.
    func parseIndexes(_ input: String, optionCount: Int) -> [Int] {
        let seen = Set(
            input
                .split { $0 == "," || $0 == " " }
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .map { $0 - 1 }
                .filter { 0 ..< optionCount ~= $0 },
        )
        return seen.sorted()
    }
}
