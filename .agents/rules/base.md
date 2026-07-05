# Interaction - A Terminal Interaction Library

A Swift library for building terminal UIs on macOS 26+: text prompts, single/multiple choice menus, table rendering, styled text, and validation primitives.

## Directory Structure

| Path | Purpose |
|------|---------|
| `Sources/Interaction/` | Module root: `Terminal.swift` (entry point + interactive prompt routing), `Terminal+LineMode.swift` (non-interactive `readLine()` fallback), `Table.swift`, `Validation.swift`, `InteractionProviding+*.swift` convenience extensions |
| `Sources/Interaction/Selection/` | `ChoiceOption`, single/multiple selection state machines |
| `Sources/Interaction/Input/` | Terminal key vocabulary, raw-input reader, capability detection |
| `Sources/Interaction/Styling/` | `StyledText`, its renderer, terminal display-width calculation |
| `Sources/Interaction/Prompts/` | Prompt config types, per-prompt-kind interactive loops, shared block-redraw/rendering helpers |
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

## Code Review Checklist

Apply these when reviewing or refactoring code in this repo:

- **Directory splits stay behavior-neutral.** Prefer pure `git mv` in its own commit before any content edit — git records clean renames, and a bisect/revert stays possible. Verify SPM still builds with no `Package.swift` change (it auto-discovers sources recursively).
- **No lone-file directories, no all-directory root.** Group ≥2-3 related files per subdirectory; keep the public entry point and single-file concerns (e.g. `Table.swift`, `Validation.swift`) at the module root rather than forcing them into a directory of one.
- **Comment the "why", not the "what".** Add comments only where logic has a non-obvious invariant or encodes an external spec — ANSI escape sequences, UTF-8 byte-length ranges, Unicode East Asian Width (cite UAX #11), loop termination arguments, intentional silent-drop/dedup behavior. Skip comments on self-explanatory code.
- **Don't extract abstractions from superficially similar code.** Before factoring out a shared helper, check what's actually identical across call sites vs. what only looks similar — if the guard condition, the non-shared branch, and the render/return shape all differ, the "dedup" adds an awkward helper for near-zero line savings. Leave near-duplicates alone unless the shared part is substantial.
- **Widening access (`private` → `internal`) to enable a file split is fine** as long as it stays module-internal and no `public` signature changes.
- **Re-run `swift build`, `swift test`, and `make lint` after every content-changing commit**, not just at the end — comments and moves can't logically break tests, but the pre-commit hook (`swiftlint --strict` + my-swift-linter) will hard-block a bad commit, and it's cheaper to catch drift immediately.
- **Check `docsync.yml` after moving or editing any file it tracks** (`docsync check` / `docsync update-checksum`) — moved source paths and edited files both invalidate its checksums, and the pre-commit hook fails the commit until resynced.
- **Clean up untracked cruft found along the way** (e.g. stray `.DS_Store`) as part of the same pass, even if unrelated to the main task.
