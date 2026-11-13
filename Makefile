# All commands go through FVM so everyone uses the Flutter version in .fvmrc.
# Usage: make help

FLUTTER := fvm flutter
DART    := fvm dart
FLAVOR  ?= dev
FLAVORS := dev qa staging uat prod

.DEFAULT_GOAL := help
.PHONY: help setup env get gen watch l10n format format-check analyze test \
        feature usecase bump version \
        coverage check icons clean run-dev run-qa run-staging run-uat run-prod \
        build-apk build-appbundle build-ipa build-ios-nosign integration

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

setup: ## First-time setup: fvm install, env files, pub get, codegen
	fvm install
	$(MAKE) env get gen

env: ## Copy env/*.example.json to env/*.json (never overwrites)
	@for f in $(FLAVORS); do \
	  [ -f env/$$f.json ] || { cp env/$$f.example.json env/$$f.json && echo "created env/$$f.json"; }; \
	done

get: ## flutter pub get
	$(FLUTTER) pub get

gen: ## Generate freezed/json + l10n code
	$(DART) run build_runner build --delete-conflicting-outputs
	$(FLUTTER) gen-l10n

watch: ## Regenerate code on change
	$(DART) run build_runner watch --delete-conflicting-outputs

l10n: ## Regenerate localizations only
	$(FLUTTER) gen-l10n

format: ## Format all Dart code
	$(DART) format .

format-check: ## Fail if code is not formatted
	$(DART) format --set-exit-if-changed .

analyze: ## Static analysis
	$(FLUTTER) analyze

test: ## Run unit + widget tests
	$(FLUTTER) test

coverage: ## Run tests with coverage (coverage/lcov.info)
	$(FLUTTER) test --coverage

check: format-check analyze test ## What CI runs (after gen)

feature: ## Scaffold a feature: make feature NAME=orders [ENTITY=order]
	@[ -n "$(NAME)" ] || { echo "usage: make feature NAME=orders [ENTITY=order]"; exit 1; }
	tool/new_feature.sh $(NAME) $(if $(ENTITY),--entity $(ENTITY))

usecase: ## Add a use case: make usecase FEATURE=orders NAME=create_order [RETURNS=Order] [NO_PARAMS=1]
	@[ -n "$(FEATURE)" ] && [ -n "$(NAME)" ] || { echo "usage: make usecase FEATURE=orders NAME=create_order [RETURNS=Order] [NO_PARAMS=1]"; exit 1; }
	tool/add_usecase.sh $(FEATURE) $(NAME) $(if $(RETURNS),--returns "$(RETURNS)") $(if $(NO_PARAMS),--no-params)

version: ## Print the current app version
	@sed -n "s/^version: *//p" pubspec.yaml

bump: ## Bump version: make bump PART=patch|minor|major|build|X.Y.Z [TAG=1]
	tool/bump_version.sh $(or $(PART),patch) $(if $(TAG),--tag)

icons: ## Regenerate launcher icons for every flavor
	$(DART) run flutter_launcher_icons

integration: ## Run integration tests on a connected device (FLAVOR=dev)
	$(FLUTTER) test integration_test --flavor $(FLAVOR) \
	  --dart-define-from-file=env/$(FLAVOR).json

clean: ## flutter clean
	$(FLUTTER) clean

run-dev: ## Run dev flavor
	$(FLUTTER) run --flavor dev -t lib/main_dev.dart --dart-define-from-file=env/dev.json

run-qa: ## Run qa flavor
	$(FLUTTER) run --flavor qa -t lib/main_qa.dart --dart-define-from-file=env/qa.json

run-staging: ## Run staging flavor
	$(FLUTTER) run --flavor staging -t lib/main_staging.dart --dart-define-from-file=env/staging.json

run-uat: ## Run uat flavor
	$(FLUTTER) run --flavor uat -t lib/main_uat.dart --dart-define-from-file=env/uat.json

run-prod: ## Run prod flavor
	$(FLUTTER) run --flavor prod -t lib/main_prod.dart --dart-define-from-file=env/prod.json

build-apk: ## Release APK: make build-apk FLAVOR=qa
	$(FLUTTER) build apk --release --flavor $(FLAVOR) -t lib/main_$(FLAVOR).dart \
	  --dart-define-from-file=env/$(FLAVOR).json

build-appbundle: ## Release AAB for Play: make build-appbundle FLAVOR=prod
	$(FLUTTER) build appbundle --release --flavor $(FLAVOR) -t lib/main_$(FLAVOR).dart \
	  --dart-define-from-file=env/$(FLAVOR).json

build-ipa: ## Release IPA (needs signing): make build-ipa FLAVOR=qa
	$(FLUTTER) build ipa --release --flavor $(FLAVOR) -t lib/main_$(FLAVOR).dart \
	  --dart-define-from-file=env/$(FLAVOR).json

build-ios-nosign: ## iOS build without code signing: make build-ios-nosign FLAVOR=qa
	$(FLUTTER) build ios --no-codesign --flavor $(FLAVOR) -t lib/main_$(FLAVOR).dart \
	  --dart-define-from-file=env/$(FLAVOR).json
