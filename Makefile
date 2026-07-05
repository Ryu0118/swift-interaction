SWIFTFORMAT := .nest/bin/swiftformat
SWIFTLINT := .nest/bin/swiftlint
MY_SWIFT_LINTER := .nest/bin/my-swift-linter
MY_SWIFT_LINTER_PATHS := Sources Tests Package.swift

.PHONY: install-commands format swiftlint lint my-lint format-lint hooks test docs check

install-commands:
	mise install
	./scripts/nest.sh bootstrap nestfile.yaml

format:
	@test -f "$(SWIFTFORMAT)" || (echo "Run: make install-commands" && exit 1)
	"$(SWIFTFORMAT)" --config .swiftformat .

swiftlint:
	@test -f "$(SWIFTLINT)" || (echo "Run: make install-commands" && exit 1)
	"$(SWIFTLINT)" lint --config .swiftlint.yml --strict --no-cache

my-lint:
	@test -f "$(MY_SWIFT_LINTER)" || (echo "Run: make install-commands" && exit 1)
	"$(MY_SWIFT_LINTER)" --config .swift-ast-lint.yml --no-cache $(MY_SWIFT_LINTER_PATHS)

lint: swiftlint my-lint

format-lint: format lint

hooks:
	./scripts/setup-hooks.sh

test:
	swift test

docs:
	CLANG_MODULE_CACHE_PATH=.build/module-cache swift package --disable-sandbox \
		--cache-path .build/swiftpm-cache \
		--config-path .build/swiftpm-config \
		--security-path .build/swiftpm-security \
		generate-documentation --target Interaction

check: format lint test
