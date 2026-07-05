import Foundation

public extension String {
    /// The number of columns this string occupies in a terminal.
    var terminalDisplayWidth: Int {
        let visible = contains("\u{1B}") ? withoutANSIEscapeSequences : self
        return visible.reduce(into: 0) { width, character in
            width += character.terminalDisplayWidth
        }
    }

    /// The string with ANSI escape sequences removed.
    package var withoutANSIEscapeSequences: String {
        var result = ""
        var iterator = makeIterator()

        while let character = iterator.next() {
            guard character == "\u{1B}" else {
                result.append(character)
                continue
            }

            guard iterator.next() == "[" else {
                continue
            }

            while let next = iterator.next() {
                if next.isANSIFinalByte {
                    break
                }
            }
        }

        return result
    }
}

public extension Character {
    /// The number of columns this character occupies in a terminal.
    var terminalDisplayWidth: Int {
        guard !unicodeScalars.allSatisfy(\.isZeroWidth) else {
            return 0
        }

        if unicodeScalars.contains(where: \.isEmojiPresentationCluster) {
            return 2
        }

        return unicodeScalars.map(\.terminalDisplayWidth).max() ?? 0
    }
}

private extension Character {
    var isANSIFinalByte: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else {
            return false
        }
        return (0x40 ... 0x7E).contains(scalar.value)
    }
}

private extension Unicode.Scalar {
    var terminalDisplayWidth: Int {
        if isZeroWidth {
            return 0
        }
        if isWide {
            return 2
        }
        return 1
    }

    var isEmojiPresentationCluster: Bool {
        properties.isEmojiPresentation || properties.isEmojiModifier || properties.isEmojiModifierBase || isRegionalIndicator
    }

    /// Combining marks, NUL, and the two Unicode mechanisms used to build
    /// multi-scalar grapheme clusters (ZWJ `U+200D` for emoji sequences like
    /// family/profession emoji, and variation selectors `U+FE00...FE0F` that
    /// pick an emoji vs. text presentation) all occupy zero terminal columns
    /// on their own — their width is already counted via the base scalar.
    var isZeroWidth: Bool {
        properties.generalCategory == .nonspacingMark ||
            properties.generalCategory == .enclosingMark ||
            value == 0x00 ||
            value == 0x200D ||
            (0xFE00 ... 0xFE0F).contains(value)
    }

    var isRegionalIndicator: Bool {
        (0x1F1E6 ... 0x1F1FF).contains(value)
    }

    /// Whether Unicode East Asian Width classifies this scalar as Wide (W) or
    /// Fullwidth (F), i.e. it renders as two terminal columns. See UAX #11:
    /// https://www.unicode.org/reports/tr11/
    var isWide: Bool {
        switch value {
        case 0x1100 ... 0x115F,
             0x231A ... 0x231B,
             0x2329 ... 0x232A,
             0x23E9 ... 0x23EC,
             0x23F0,
             0x23F3,
             0x25FD ... 0x25FE,
             0x2614 ... 0x2615,
             0x2648 ... 0x2653,
             0x267F,
             0x2693,
             0x26A1,
             0x26AA ... 0x26AB,
             0x26BD ... 0x26BE,
             0x26C4 ... 0x26C5,
             0x26CE,
             0x26D4,
             0x26EA,
             0x26F2 ... 0x26F3,
             0x26F5,
             0x26FA,
             0x26FD,
             0x2705,
             0x270A ... 0x270B,
             0x2728,
             0x274C,
             0x274E,
             0x2753 ... 0x2755,
             0x2757,
             0x2795 ... 0x2797,
             0x27B0,
             0x27BF,
             0x2B1B ... 0x2B1C,
             0x2B50,
             0x2B55,
             0x2E80 ... 0xA4CF,
             0xAC00 ... 0xD7A3,
             0xF900 ... 0xFAFF,
             0xFE10 ... 0xFE19,
             0xFE30 ... 0xFE6F,
             0xFF00 ... 0xFF60,
             0xFFE0 ... 0xFFE6,
             0x1F000 ... 0x1FAFF,
             0x20000 ... 0x3FFFD:
            true
        default:
            false
        }
    }
}
