@testable import Interaction
import Testing

@Suite("Edits a line buffer by Unicode grapheme cluster, keeping composed characters and emoji sequences intact")
struct LineBufferTests {
    @Test("inserting Japanese text advances the cursor by grapheme count, and backspacing after moving left removes the middle character")
    func insertsAndDeletesJapaneseTextByGraphemeCluster() {
        var buffer = LineBuffer()

        buffer.insert("日本語")
        #expect(buffer.text == "日本語")
        #expect(buffer.cursorOffset == 3)
        #expect(buffer.cursorDisplayColumn == 6)

        buffer.moveCursorLeft()
        buffer.backspace()

        #expect(buffer.text == "日語")
        #expect(buffer.cursorOffset == 1)
        #expect(buffer.cursorDisplayColumn == 2)
    }

    @Test("backspacing at the end of a combining-accent string removes the whole composed grapheme instead of splitting the base and combining mark")
    func keepsComposedCharactersIntactWhileEditing() {
        var buffer = LineBuffer("Cafe\u{301}")

        #expect(buffer.text == "Cafe\u{301}")
        #expect(buffer.cursorOffset == 4)
        #expect(buffer.cursorDisplayColumn == 4)

        buffer.backspace()

        #expect(buffer.text == "Caf")
        #expect(buffer.cursorOffset == 3)
        #expect(buffer.cursorDisplayColumn == 3)
    }

    @Test("backspacing over a multi-codepoint ZWJ family emoji deletes the entire sequence as a single character, not one codepoint")
    func treatsEmojiSequencesAsOneEditableUnit() {
        var buffer = LineBuffer("A👨‍👩‍👧‍👦B")

        #expect(buffer.cursorOffset == 3)
        #expect(buffer.cursorDisplayColumn == 4)

        buffer.moveCursorLeft()
        buffer.backspace()

        #expect(buffer.text == "AB")
        #expect(buffer.cursorOffset == 1)
        #expect(buffer.cursorDisplayColumn == 1)
    }

    @Test("forward-deleting after moving past a wide character removes only the emoji modifier sequence, leaving surrounding characters untouched")
    func deletesAtCursorWithoutCrossingCharacterBoundaries() {
        var buffer = LineBuffer("あb👍🏽c")

        buffer.moveCursorToBeginning()
        buffer.moveCursorRight()
        buffer.moveCursorRight()
        buffer.delete()

        #expect(buffer.text == "あbc")
        #expect(buffer.cursorOffset == 2)
        #expect(buffer.cursorDisplayColumn == 3)
    }

    @Test("replacing the buffer's contents resets the text and moves the cursor to the end of the new, mixed-width value")
    func supportsReplacingTheCurrentLine() {
        var buffer = LineBuffer("old")

        buffer.replace(with: "新しい value")

        #expect(buffer.text == "新しい value")
        #expect(buffer.cursorOffset == 9)
        #expect(buffer.cursorDisplayColumn == 12)
    }
}
