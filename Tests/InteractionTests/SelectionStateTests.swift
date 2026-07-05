@testable import Interaction
import Testing

@Suite("Tracks cursor position and selection for single- and multiple-choice option lists, including filtering and selection limits")
struct SelectionStateTests {
    @Test("moving the cursor down then filtering to a single remaining option clamps the cursor to it and keeps it selected")
    func singleSelectionClampsCursorWhenFilteringShrinksOptions() {
        var state = SingleSelectionState(
            options: ["Alpha", "ベータ", "日本語", "Gamma"].map { ChoiceOption($0) },
        )

        state.moveDown()
        state.moveDown()
        state.moveDown()
        state.filter = "日"

        #expect(state.visibleOptions.map(\.value) == ["日本語"])
        #expect(state.cursorIndex == 0)
        #expect(state.selected?.value == "日本語")
    }

    @Test("filtering by a lowercase, unaccented query matches options that differ in case or diacritics")
    func singleSelectionFiltersCaseAndDiacriticInsensitively() {
        var state = SingleSelectionState(
            options: ["Café", "CafeKit", "Swift"].map { ChoiceOption($0) },
        )

        state.filter = "cafe"

        #expect(state.visibleOptions.map(\.value) == ["Café", "CafeKit"])
    }

    @Test("adding a third option is rejected once the maximum of two is reached, while removing and re-adding options below that cap stays within the minimum of one")
    func multipleSelectionRespectsMinAndMaxLimits() {
        var state = MultipleSelectionState(
            options: ["one", "two", "three"].map { ChoiceOption($0) },
            minimumSelectionCount: 1,
            maximumSelectionCount: 2,
        )

        state.toggleFocusedOption()
        state.moveDown()
        state.toggleFocusedOption()
        state.moveDown()
        state.toggleFocusedOption()

        #expect(state.selectedValues == ["one", "two"])

        state.moveCursorToBeginning()
        state.toggleFocusedOption()

        #expect(state.selectedValues == ["two"])

        state.toggleFocusedOption()

        #expect(state.selectedValues == ["one", "two"])
    }
}
