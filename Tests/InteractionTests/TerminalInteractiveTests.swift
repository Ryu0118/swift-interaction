import Foundation
@testable import Interaction
import Testing

private final class ScriptedKeyInput: KeyInput, @unchecked Sendable {
    private var keys: [TerminalKey]

    init(_ keys: [TerminalKey]) {
        self.keys = keys
    }

    func readKey() -> TerminalKey? {
        keys.isEmpty ? nil : keys.removeFirst()
    }
}

private final class ScriptedLineInput: TextInput, @unchecked Sendable {
    private var lines: [String]

    init(_ lines: [String]) {
        self.lines = lines
    }

    func readLine() -> String? {
        lines.isEmpty ? nil : lines.removeFirst()
    }
}

private final class CapturedOutput: TextOutput, @unchecked Sendable {
    private var buffer = ""

    var text: String {
        buffer
    }

    func write(_ text: String) {
        buffer += text
    }
}

@Suite("Drives Terminal's interactive prompts (choose, chooseMany, readText, confirm) against scripted key and line input")
struct TerminalInteractiveTests {
    private static func makeTerminal(
        keys: [TerminalKey] = [],
        lines: [String] = [],
        isInteractive: Bool = true,
        width: Int? = nil,
    ) -> (terminal: Terminal, output: CapturedOutput) {
        let output = CapturedOutput()
        let terminal = Terminal(
            input: ScriptedLineInput(lines),
            keyInput: ScriptedKeyInput(keys),
            output: output,
            capabilities: TerminalCapabilities(isInteractive: isInteractive, supportsColor: false, width: width),
        )
        return (terminal, output)
    }

    @Test("pressing down then enter selects the second option and renders the cursor marker and confirmed answer")
    func chooseNavigatesOptionsWithArrowKeys() {
        let (terminal, output) = Self.makeTerminal(keys: [.down, .enter])

        let answer = terminal.choose(ChoicePrompt(question: "Pick one", options: ["first", "second", "third"]))

        #expect(answer == "second")
        #expect(output.text.contains("❯"))
        #expect(output.text.contains("Pick one ✓ second"))
    }

    @Test("typing characters filters the option list and enter selects the matching option, echoing the typed filter text")
    func chooseFiltersOptionsByTypedText() {
        let (terminal, output) = Self.makeTerminal(keys: [.character("b"), .character("a"), .enter])

        let answer = terminal.choose(ChoicePrompt(question: "Pick", options: ["apple", "banana"]))

        #expect(answer == "banana")
        #expect(output.text.contains("Pick (filter: ba)"))
    }

    @Test("toggling with space, moving down twice, and toggling again selects the first and third options and renders a filled marker plus the confirmed list")
    func chooseManyTogglesOptionsWithSpace() {
        let (terminal, output) = Self.makeTerminal(keys: [.character(" "), .down, .down, .character(" "), .enter])

        let answer = terminal.chooseMany(MultipleChoicePrompt(question: "Pick", options: ["a", "b", "c"]))

        #expect(answer == ["a", "c"])
        #expect(output.text.contains("● a"))
        #expect(output.text.contains("Pick ✓ a, c"))
    }

    @Test("pressing enter with nothing selected re-prompts with a minimum-selection warning until at least one option is toggled")
    func chooseManyEnforcesTheMinimumSelectionCount() {
        let (terminal, output) = Self.makeTerminal(keys: [.enter, .character(" "), .enter])

        let answer = terminal.chooseMany(
            MultipleChoicePrompt(question: "Pick", options: ["a", "b"], minimumSelectionCount: 1),
        )

        #expect(answer == ["a"])
        #expect(output.text.contains("! Select at least 1 option(s)."))
    }

    @Test("typing two characters, moving left, backspacing, and typing another character produces the edited buffer contents, not the original keystroke order")
    func readTextEditsTheBufferWithCursorKeys() async {
        let (terminal, _) = Self.makeTerminal(
            keys: [.character("a"), .character("b"), .left, .backspace, .character("c"), .enter],
        )

        let answer = await terminal.readText(TextPrompt(message: "Name:"))

        #expect(answer == "cb")
    }

    @Test("submitting empty input against a non-empty validation rule re-prompts with an error message until valid text is entered")
    func readTextRePromptsUntilValidationPasses() async {
        let (terminal, output) = Self.makeTerminal(keys: [.enter, .character("x"), .enter])

        let answer = await terminal.readText(
            TextPrompt(message: "Name:", validationRules: [.nonEmpty()]),
        )

        #expect(answer == "x")
        #expect(output.text.contains("! Input cannot be empty."))
    }

    @Test("enter answers a confirmation prompt yes while typing 'n' answers no, and the yes case echoes the confirmed answer")
    func confirmAnswersWithASingleKey() {
        let (yesTerminal, yesOutput) = Self.makeTerminal(keys: [.enter])
        let (noTerminal, _) = Self.makeTerminal(keys: [.character("n")])

        #expect(yesTerminal.confirm(ConfirmationPrompt(question: "Continue?")) == true)
        #expect(noTerminal.confirm(ConfirmationPrompt(question: "Continue?")) == false)
        #expect(yesOutput.text.contains("Continue? ✓ yes"))
    }

    @Test("when the terminal is non-interactive, choose renders a numbered list and reads the selection index from a line of text input")
    func nonInteractiveSessionsFallBackToNumberedPrompts() {
        let (terminal, output) = Self.makeTerminal(lines: ["2"], isInteractive: false)

        let answer = terminal.choose(ChoicePrompt(question: "Pick one", options: ["first", "second"]))

        #expect(answer == "second")
        #expect(output.text.contains("1. first"))
    }

    @Test("writeTable wraps table rows to the detected terminal width")
    func writeTableWrapsToTerminalWidth() {
        let (terminal, output) = Self.makeTerminal(width: 24)

        terminal.writeTable(Table(
            headers: ["name", "description"],
            rows: [["Project", "A project template"]],
        ))

        let lines = output.text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .dropLast()
            .map(String.init)

        #expect(lines.allSatisfy { $0.terminalDisplayWidth <= 24 })
        #expect(output.text.contains("│ Project"))
        #expect(output.text.contains("│ template"))
    }

    @Test("a choice prompt with a title and description renders both the title marker and indented description above the question")
    func interactivePromptsRenderTitleAndDescriptionHierarchy() {
        let (terminal, output) = Self.makeTerminal(keys: [.enter])

        _ = terminal.choose(
            ChoicePrompt(
                title: "Template",
                question: "Pick one",
                options: ["Package"],
                description: "Choose the starter to hatch.",
                automaticallySelectsSingleOption: false,
            ),
        )

        #expect(output.text.contains("◆ Template"))
        #expect(output.text.contains("  Choose the starter to hatch."))
    }

    @Test("filtering to a query with no matches shows a 'no matches' message, and backspacing to clear the filter restores the option list for selection")
    func choicePromptRendersAnEmptyFilteredState() {
        let (terminal, output) = Self.makeTerminal(keys: [.character("z"), .backspace, .enter])

        let answer = terminal.choose(ChoicePrompt(question: "Pick", options: ["apple", "banana"]))

        #expect(answer == "apple")
        #expect(output.text.contains("(no matches)"))
    }
}
