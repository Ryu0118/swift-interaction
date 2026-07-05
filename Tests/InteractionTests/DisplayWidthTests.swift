@testable import Interaction
import Testing

@Suite("Computes terminal display width for ASCII, CJK, combining marks, and emoji sequences")
struct DisplayWidthTests {
    @Test("computes the terminal column width for ASCII, CJK, accented, and emoji strings, matching each case's expected width", arguments: DisplayWidthCase.allCases)
    func measuresTerminalDisplayColumns(_ testCase: DisplayWidthCase) {
        #expect(testCase.value.terminalDisplayWidth == testCase.expectedWidth)
    }

    @Test("excludes ANSI color escape codes from the display width of a string wrapping Japanese text")
    func ignoresAnsiEscapeSequencesWhileMeasuring() {
        let styled = "\u{1B}[31m日本語\u{1B}[0m"

        #expect(styled.terminalDisplayWidth == 6)
    }

    struct DisplayWidthCase: CustomTestStringConvertible {
        let description: String
        let value: String
        let expectedWidth: Int

        static let allCases: [Self] = [
            Self(description: "ASCII", value: "abc", expectedWidth: 3),
            Self(description: "Japanese", value: "日本語", expectedWidth: 6),
            Self(description: "Korean", value: "한글", expectedWidth: 4),
            Self(description: "Chinese", value: "中文", expectedWidth: 4),
            Self(description: "composed accent", value: "e\u{301}", expectedWidth: 1),
            Self(description: "emoji", value: "👍", expectedWidth: 2),
            Self(description: "emoji modifier sequence", value: "👍🏽", expectedWidth: 2),
            Self(description: "family emoji zwj sequence", value: "👨‍👩‍👧‍👦", expectedWidth: 2),
            Self(description: "flag sequence", value: "🇯🇵", expectedWidth: 2),
        ]

        var testDescription: String {
            description
        }
    }
}
