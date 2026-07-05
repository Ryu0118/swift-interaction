@testable import Interaction
import Testing

@Suite("Renders StyledText segments to plain or ANSI-colorized terminal output")
struct StyledTextRendererTests {
    @Test("a non-colorized renderer converts command and path segments into their plain textual form (quoted command, bare path) with no ANSI codes")
    func plainRenderingStripsAllStyling() {
        let renderer = StyledTextRenderer(colorized: false)
        let text: StyledText = "Run \(StyledText.Segment.command("egg hatch")) in \(StyledText.Segment.path("/tmp"))"

        #expect(renderer.render(text) == "Run 'egg hatch' in /tmp")
    }

    @Test("a colorized renderer wraps a success segment in the green SGR escape sequence while leaving surrounding plain text untouched")
    func colorizedRenderingWrapsStyledSegmentsInSGRCodes() {
        let renderer = StyledTextRenderer(colorized: true)
        let text: StyledText = "\(StyledText.Segment.success("Added")) file"

        #expect(renderer.render(text) == "\u{1B}[32mAdded\u{1B}[0m file")
    }

    @Test("a colorized renderer passes through a message with no styled segments unchanged")
    func colorizedRenderingLeavesPlainSegmentsUntouched() {
        let renderer = StyledTextRenderer(colorized: true)

        #expect(renderer.render("plain message") == "plain message")
    }

    @Test("stripping ANSI escapes from a colorized render of danger, muted, and link segments reproduces the same text as StyledText's plain-text representation")
    func colorizedRenderingMatchesPlainTextAfterStrippingEscapes() {
        let renderer = StyledTextRenderer(colorized: true)
        let text: StyledText = "\(StyledText.Segment.danger("error")): \(StyledText.Segment.muted("details")) \(StyledText.Segment.link(title: "docs", destination: "https://example.com"))"

        #expect(renderer.render(text).withoutANSIEscapeSequences == text.plainText)
    }
}
