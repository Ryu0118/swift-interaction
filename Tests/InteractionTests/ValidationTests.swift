@testable import Interaction
import Testing

@Suite("Validates ValidationError, ValidationRule, and rule collections used by text prompts")
struct ValidationTests {
    @Test("a ValidationError's localizedDescription returns the message it was constructed with")
    func validationErrorExposesLocalizedMessage() {
        let error = ValidationError("Expected message")

        #expect(error.localizedDescription == "Expected message")
    }

    @Test(".nonEmpty returns nil for non-empty input and returns its configured message for empty input")
    func nonEmptyRuleReturnsNilForValidInput() async {
        let rule = ValidationRule.nonEmpty(message: "Required")

        await #expect(rule("value") == nil)
        await #expect(rule("")?.message == "Required")
    }

    @Test("an array of validation rules returns the messages of every rule that fails, and an empty array when input satisfies all rules")
    func validationRuleCollectionsReturnErrors() async {
        let shortRule = ValidationRule { input in
            input.count <= 4 ? nil : ValidationError("Must be short")
        }
        let rules: [ValidationRule] = [.nonEmpty(message: "Required"), shortRule]

        await #expect(rules.validate("").map(\.message) == ["Required"])
        await #expect(rules.validate("abcdefgh").map(\.message) == ["Must be short"])
        await #expect(rules.validate("abc").isEmpty)
    }

    @Test("a rule's error message can be computed dynamically from the input it rejects")
    func validationRulesCanReportDynamicMessages() async {
        let rule = ValidationRule { input in
            input.count.isMultiple(of: 2) ? nil : ValidationError("'\(input)' must have even length")
        }

        await #expect(rule("ab") == nil)
        await #expect(rule("abc")?.message == "'abc' must have even length")
    }

    @Test("a rule's closure can await asynchronous work before returning its verdict")
    func validationRulesCanBeAsynchronous() async {
        let rule = ValidationRule { input in
            await Task.yield()
            return input == "known" ? nil : ValidationError("Unknown value")
        }

        await #expect(rule("known") == nil)
        await #expect(rule("other")?.message == "Unknown value")
    }
}
