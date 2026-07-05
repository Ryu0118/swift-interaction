public extension InteractionProviding {
    /// Reads text using a concise, keyword-based prompt convenience.
    func textPrompt(
        title: StyledText? = nil,
        prompt: StyledText,
        description: StyledText? = nil,
        collapsesOnAnswer: Bool = true,
        validationRules: [any ValidationRule] = [],
    ) -> String {
        readText(
            TextPrompt(
                title: title,
                message: prompt,
                description: description,
                collapsesOnAnswer: collapsesOnAnswer,
                validationRules: validationRules,
            ),
        )
    }

    /// Reads a yes/no answer using a concise, keyword-based prompt convenience.
    func yesOrNoChoicePrompt(
        title: StyledText? = nil,
        question: StyledText,
        defaultAnswer: Bool = true,
        description: StyledText? = nil,
        collapsesOnAnswer: Bool = true,
    ) -> Bool {
        confirm(
            ConfirmationPrompt(
                title: title,
                question: question,
                defaultAnswer: defaultAnswer,
                description: description,
                collapsesOnAnswer: collapsesOnAnswer,
            ),
        )
    }

    /// Reads one option using a concise, keyword-based prompt convenience.
    func singleChoicePrompt<Option>(
        title: StyledText? = nil,
        question: StyledText,
        options: [Option],
        description: StyledText? = nil,
        allowsFiltering: Bool = true,
        collapsesOnSelection: Bool = true,
        automaticallySelectsSingleOption: Bool = true,
    ) -> Option where Option: Equatable & CustomStringConvertible & Sendable {
        choose(
            ChoicePrompt(
                title: title,
                question: question,
                options: options,
                description: description,
                allowsFiltering: allowsFiltering,
                collapsesOnSelection: collapsesOnSelection,
                automaticallySelectsSingleOption: automaticallySelectsSingleOption,
            ),
        )
    }

    /// Reads multiple options using a concise, keyword-based prompt convenience.
    func multipleChoicePrompt<Option>(
        title: StyledText? = nil,
        question: StyledText,
        options: [Option],
        description: StyledText? = nil,
        allowsFiltering: Bool = true,
        collapsesOnSelection: Bool = true,
        minimumSelectionCount: Int = 0,
        maximumSelectionCount: Int? = nil,
    ) -> [Option] where Option: Equatable & CustomStringConvertible & Sendable {
        chooseMany(
            MultipleChoicePrompt(
                title: title,
                question: question,
                options: options,
                description: description,
                allowsFiltering: allowsFiltering,
                collapsesOnSelection: collapsesOnSelection,
                minimumSelectionCount: minimumSelectionCount,
                maximumSelectionCount: maximumSelectionCount,
            ),
        )
    }
}
