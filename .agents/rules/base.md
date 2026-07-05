# Interaction — A Terminal Interaction Library

A Swift library for building terminal UIs on macOS 26+: text prompts, single/multiple choice menus, table rendering, styled text, and validation primitives.

## Directory Structure

| Path | Purpose |
|------|---------|
| `Sources/Interaction/` | **All implementation**. Prompts, choice loops, selection state, table/styled-text rendering, validation, terminal capabilities |
| `Sources/Interaction/Interaction.docc/` | DocC catalog: landing page and Getting Started |
| `Tests/InteractionTests/` | Unit tests |

## Entry Point

`Terminal` is the public entry point: construct one and call `readText(_:)`, `confirm(_:)`, `choose(_:)`, `chooseMany(_:)`, `write(_:)`, `writeStatus(_:_:)`, `writeTable(_:)`.

## Available Skills

| Skill | When to use |
|-------|-------------|
| `interaction-guide` | Using the Interaction public API (prompts, choices, tables, styled text, validation) |

## Notes

- Swift 6.2 / macOS 26+
- Use `public` for the library API surface; `package` only for module-internal cross-file helpers.
- Runtime code has no external package dependencies (only `swift-docc-plugin`, for docs). Do not add runtime dependencies without a strong reason.
- `make lint` runs both SwiftLint and my-swift-linter. Install hooks with `make hooks`; pre-push runs `make my-lint`.
- `make docs` builds the Interaction DocC archive.
