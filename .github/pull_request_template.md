## What & why

<!-- What does this PR change, and why? Link the issue: Closes #123 -->

## Type

- [ ] feat
- [ ] fix
- [ ] refactor
- [ ] test
- [ ] docs
- [ ] chore

## Checklist

- [ ] PR title follows Conventional Commits (`feat: …`, `fix: …`)
- [ ] Target branch is `develop` (or `main` for a release/hotfix)
- [ ] Tests added/updated (unit, `blocTest`, widget) for the change
- [ ] `make gen` (build_runner) run after model/bloc/state changes
- [ ] `fvm dart format .` run, `fvm flutter analyze` is clean
- [ ] `fvm flutter test` passes locally
- [ ] Architecture rules respected (no cross-feature imports, no `sl()` outside DI/route builders, blocs use use cases only)
- [ ] New env keys added to **every** `env/*.example.json` (no secrets in code)
- [ ] Flavors tested: <!-- e.g. dev on Android emulator, qa on iPhone 16 -->
  - [ ] dev
  - [ ] qa
  - [ ] staging
  - [ ] uat
  - [ ] prod
- [ ] Strings added to `lib/core/l10n/app_en.arb` (no hard-coded UI text)

## Screenshots / recordings (UI changes)

| Before | After |
| ------ | ----- |
|        |       |

## Notes for the reviewer

<!-- Anything tricky, follow-ups, or things you want a second opinion on. -->
