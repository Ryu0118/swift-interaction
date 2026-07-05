@testable import Interaction
import Testing

@Suite("Validates ValidationError, PredicateValidationRule, and rule collections used by text prompts")
struct ValidationTests {
    @Test("a ValidationError's localizedDescription returns the message it was constructed with")
    func validationErrorExposesLocalizedMessage() {
        let error = ValidationError("Expected message")

        #expect(error.localizedDescription == "Expected message")
    }

    @Test("NonEmptyRule returns nil for non-empty input and returns its configured message for empty input")
    func validationRulesReturnNilForValidInput() {
        let rule = NonEmptyRule(message: "Required")

        #expect(rule.validate("value") == nil)
        #expect(rule.validate("")?.message == "Required")
    }

    @Test("an array of validation rules returns the messages of every rule that fails, and an empty array when input satisfies all rules")
    func validationRuleCollectionsReturnErrors() {
        struct ShortRule: PredicateValidationRule {
            let error = ValidationError("Must be short")

            func validate(input: String) -> Bool {
                input.count <= 4
            }
        }

        let rules: [any ValidationRule] = [NonEmptyRule(message: "Required"), ShortRule()]

        #expect(rules.validate("").map(\.message) == ["Required"])
        #expect(rules.validate("abcdefgh").map(\.message) == ["Must be short"])
        #expect(rules.validate("abc").isEmpty)
    }

    @Test("a custom PredicateValidationRule returns nil when its predicate passes and its own error when the predicate fails")
    func predicateValidationRulesBridgeToValidationErrors() {
        struct EvenLengthRule: PredicateValidationRule {
            let error = ValidationError("Must have even length")

            func validate(input: String) -> Bool {
                input.count.isMultiple(of: 2)
            }
        }

        let rule = EvenLengthRule()

        #expect(rule.validate("ab") == nil)
        #expect(rule.validate("abc") == rule.error)
    }
}
