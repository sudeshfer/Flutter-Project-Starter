# Contributing

This project has two developers, and every change goes through a pull request. The workflow is below.

## Branches

| Branch | Purpose | Protected |
| --- | --- | --- |
| `main` | Release-ready code. Every commit on `main` can ship to the stores. | ✅ PR + passing CI + 1 review |
| `develop` | Integration branch. Feature work lands here first. | ✅ PR + passing CI + 1 review |
| `feature/<short-name>` | New work, branched from `develop` | – |
| `fix/<short-name>` | Bug fixes, branched from `develop` (or from `main` for a hotfix) | – |
| `release/<version>` | Release stabilisation (e.g. `release/1.2.0`), branched from `develop` | – |

Use short, lowercase, hyphenated names, e.g. `feature/order-history` or `fix/login-crash`.

### Flow

```
feature/x ──PR──▶ develop ──▶ release/1.2.0 ──PR──▶ main  (tag v1.2.0)
                     ▲                │
                     └──── merge back ┘
hotfix: fix/x (from main) ──PR──▶ main, then merge main back into develop
```

1. `git switch develop && git pull`
2. `git switch -c feature/my-thing`
3. Commit in small steps (see below), then `git push -u origin feature/my-thing`.
4. Open a PR into `develop` and fill in the template.
5. Before merging, rebase on `develop` (or merge `develop` into your branch) if it has moved on.
6. **Squash-merge** into `develop`. The PR title becomes the commit message, so it must follow Conventional Commits.
7. Delete the branch.

## Commits: Conventional Commits

```
<type>(optional scope): <short summary in the imperative>

feat(orders): add order history page
fix(network): retry GET requests on connection timeout
chore: bump flutter to 3.47.9
```

| Type | Use for |
| --- | --- |
| `feat` | A new user-facing feature |
| `fix` | A bug fix |
| `refactor` | A code change that neither fixes a bug nor adds a feature |
| `test` | Adding or fixing tests |
| `docs` | Documentation only |
| `chore` | Tooling, dependencies, CI, config |

Add `!` after the type (e.g. `feat!:`) or a `BREAKING CHANGE:` footer for breaking changes.

## Pull requests

- Keep PRs small and focused, ideally under 400 changed lines excluding generated code.
- Fill in the PR template checklist, including which flavors you tested and screenshots for UI changes.
- CI must be green: format check, analyzer (zero issues), tests, and the dev APK build.
- Don't commit generated files (`*.freezed.dart`, `*.g.dart`, `lib/core/l10n/gen/`) or real `env/*.json` files.
- If you add an env key, add it to every `env/*.example.json` and tell the other developer.
- If you change `.fvmrc` (a Flutter upgrade), do it in its own `chore:` PR.

## Review process

- Each PR needs **1 approving review** from the other developer.
- The reviewer should respond within one working day. If it's urgent, ping them directly.
- Reviewers check:
  - **Architecture:** the dependency rule (presentation → domain ← data), no cross-feature imports, no `sl()`
    outside DI files and route builders, and blocs that depend on use cases only.
  - **Correctness:** errors are mapped to `Failure`, there are loading/error/empty states, and no business logic
    lives in widgets.
  - **Tests:** new behaviour is covered.
  - **Naming and conventions:** see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Mark comments as **blocking** or **nit:**. Nits don't hold up approval.
- The author resolves the conversations and merges after approval.

## Which flavor goes to whom

| Flavor | Audience | Distribution (suggested) |
| --- | --- | --- |
| **dev** | Developers | Local builds (`make run-dev`) |
| **qa** | QA team | Firebase App Distribution / TestFlight internal, built from `develop` |
| **staging** | Internal release testing | TestFlight internal / Play internal testing, built from `release/*` |
| **uat** | UAT / stakeholders | TestFlight external / Play closed testing, built from `release/*` |
| **prod** | App Store / Play Store | Store release, built from a tag on `main` |

## Releasing

1. `git switch -c release/1.2.0 develop`
2. Bump `version:` in `pubspec.yaml` (e.g. `1.2.0+12`), then commit `chore: release 1.2.0`.
3. Ship a staging build for internal checks, then a uat build for UAT. Fix bugs on the release branch with `fix:` commits.
4. Open a PR from `release/1.2.0` into `main`. After merging, tag it (`git tag v1.2.0 && git push --tags`).
5. Merge `main` back into `develop`.
