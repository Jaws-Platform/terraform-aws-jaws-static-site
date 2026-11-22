# Contributing

`terraform-aws-jaws-static-site` is a versioned Terraform module library, published on the
[Terraform Registry](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest)
as `Jaws-Platform/jaws-static-site/aws`. It holds no state and deploys nothing: it only publishes
modules. Coding agents should read [AGENTS.md](AGENTS.md).

## Local development setup

Requirements: Terraform `>= 1.11`, [tflint](https://github.com/terraform-linters/tflint),
[terraform-docs](https://terraform-docs.io), [shellcheck](https://www.shellcheck.net),
Python 3, Node.js 24, [pre-commit](https://pre-commit.com) and the GitHub CLI
(`gh`).

```sh
git clone https://github.com/Jaws-Platform/terraform-aws-jaws-static-site.git
cd terraform-aws-jaws-static-site
npm ci                                                            # commitlint
pre-commit install --hook-type commit-msg --hook-type pre-commit  # local hooks
```

The `commit-msg` hook runs commitlint locally. The `pre-commit` hooks run
`terraform fmt`, `terraform validate`, `tflint` and `terraform-docs`. They are
conveniences only; **CI is the authoritative check**.

Run the full CI suite locally before opening a pull request:

```sh
scripts/check.sh                   # everything
scripts/check.sh modules/<name>    # one module and its examples
```

No cloud credentials are needed. Tests use `terraform test` with mocked
providers, and nothing in this repository ever runs `terraform apply`.

## Commits

Each commit message is a **single-line** Conventional Commit with a type and a scope:

```
type(scope): subject
```

- At most 100 characters, with an imperative, lowercase subject and no trailing period.
- Types: `feat`, `fix`, `perf`, `revert`, `docs`, `refactor`, `test`, `build`, `ci`, `style`, `chore`: the same set in every repository.
- The scope is required: exactly one of the scopes below. A change that spans two is two pull requests, or takes the scope it is mostly about.
- Breaking changes are marked with `!`, for example `feat(hosted-zone)!: rename an output`.
- The **only** content allowed after the header is a blank line followed by `Co-authored-by: Name <email>` trailers, in any letter case. No body text. Details belong in the pull request description.

commitlint enforces this: `@commitlint/config-conventional` plus three local rules in `tools/commitlint/`. `only-coauthor-trailers` fails on any line after the header that is not blank or a `Co-authored-by` trailer, `single-scope` fails on a list such as `feat(a,b)`, and `subject-lowercase` requires a lowercase subject except in Dependabot's fixed `chore(deps): Bump ...`. The fixtures in `tests/commitlint/` show accepted and rejected messages; CI checks them, and lints the pull request title through the same config. The standard behind it is the [repository conventions](https://github.com/jwallace145/repository-template/blob/main/repository-conventions.md).

### Scopes

Every commit names exactly one of this repository's scopes. They are `SCOPES` in `commitlint.config.mjs`; this table mirrors it, in the same order, and `npm test` fails if they drift. Adding, renaming or removing a scope goes through a pull request like any other change.

| Scope | Covers |
| --- | --- |
| `hosted-zone` | The `hosted-zone` module in `modules/hosted-zone` |
| `preview-site` | The `preview-site` module in `modules/preview-site` |
| `site-bucket` | The `site-bucket` module in `modules/site-bucket` |
| `static-site` | The `static-site` module in `modules/static-site` |
| `examples` | The examples in `examples/` and the root module that composes the modules |
| `repo` | README, CONTRIBUTING, AGENTS, commitlint, the PR and issue templates, and repository tooling |
| `deps` | Dependency updates, mostly Dependabot's |
| `release` | Release Please's release pull requests and its config |

## Pull requests

- After the initial scaffold commit, **every change reaches `main` through a
  pull request**. Direct pushes are blocked.
- Merges are **squash or rebase only**. No merge commits; history is linear.
- The **title must be a valid commit header**, scope included, because a squash merge
  uses it as the commit message. Release Please's pull requests are titled
  `chore(release): release X.Y.Z`, and Dependabot's `chore(deps): Bump ...`.
- Fill in every section of the one template, `.github/pull_request_template.md`
  (Summary, Why, Changes, Verification, Checklist). Write "n/a" rather than
  deleting one. For a fix, Why names the bug, its root cause and how to reproduce it.

CI runs these jobs on every pull request, and all of them are required on
`main`:

| Job | Checks |
|---|---|
| `commitlint` | Every commit in the range `base..head`, so rebase-merged commits are all checked |
| `pr-title` | The title passes the same commitlint config as a commit, scope included |
| `commitlint-rules` | Unit tests for the local rules, the scopes table, and the fixture messages |
| `fmt` | `terraform fmt -check -recursive` |
| `terraform` | Every module passed its `terraform (<module>)` job: `init -backend=false`, `validate`, `tflint`, `terraform test`, the terraform-docs diff, the tests of any script the module ships, and the module's examples |

The module list is discovered from the tree (`scripts/list-modules.sh`), so
adding a module needs no workflow change.

## Issues

Open issues from the forms: **Bug**, **Feature** or **Task**. Blank issues are off.

## Module standards

- **Layout.** The repository root is a module, and each building block is
  `modules/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`,
  `versions.tf`, `README.md`, `examples/basic/` and `tests/`. Whole-scenario
  examples live in `examples/<name>/` at the root, where the registry lists
  them.
- **Versions.** `required_version = ">= 1.11"`, and each provider pinned to a
  compatible range in `versions.tf`.
- **Providers.** Modules never configure a provider; the caller does.
- **Inputs.** Every input has a `description` and a `type`, and a `validation`
  block wherever the value has a known shape. Error messages say what to
  change.
- **Names.** Nothing is named after one organisation. Names come from inputs
  (`name`, `name_root`, `project`) with no organisation-specific default.
- **Tags.** Every resource-creating module tags its resources with
  `Component = "<module-name>"` and, where the resource has a name, `Name`.
  All other tags come from the caller's provider `default_tags`; modules never
  take a tag map. Sub-resources that do not inherit `default_tags` are tagged
  explicitly, and a test pins it.
- **Scripts.** Scripts a module installs live in `files/`. Python scripts ship
  `files/test_*.py` (stdlib `unittest`) and shell scripts must pass
  `shellcheck`; CI runs both.
- **Documentation.** Each `README.md` opens with what the module creates and
  why, shows a usage snippet, and ends with the terraform-docs reference
  between the `BEGIN_TF_DOCS` and `END_TF_DOCS` markers. Regenerate it with
  `terraform-docs --config .terraform-docs.yml <module directory>`; CI fails
  if the committed reference differs. Links are absolute, because the registry
  does not resolve relative ones.
- **Tests.** `terraform test` with mocked providers, in `tests/*.tftest.hcl`.

## Releases and versioning

Releases are managed by [Release Please](https://github.com/googleapis/release-please).

- One version for the whole repository (`release-type: simple`), tagged
  `vX.Y.Z`. Release Please owns `CHANGELOG.md` and `version.txt`; nobody edits
  them by hand.
- On every push to `main`, the `release-please` workflow opens or updates a
  release pull request authored by `jaws-platform-release-bot[bot]`, a GitHub
  App owned by the `Jaws-Platform` organization and installed on its
  repositories only (Contents and Pull requests, read and write). The
  repository secrets `RELEASE_BOT_CLIENT_ID` and `RELEASE_BOT_PRIVATE_KEY` are
  its credentials. CI runs on
  it like any other pull request.
- **Merging the Release Please pull request is the deliberate, human-reviewed
  act that releases a version.** Nobody creates tags by hand.
- The Terraform Registry picks up every tag and publishes it as
  [`Jaws-Platform/jaws-static-site/aws`](https://registry.terraform.io/modules/Jaws-Platform/jaws-static-site/aws/latest).
  Nothing in CI publishes.
- Usage snippets in the READMEs and examples pin the current version on lines
  marked `# x-release-please-version`, which Release Please rewrites.

Consumers pin a version:

```hcl
source  = "Jaws-Platform/jaws-static-site/aws//modules/<name>"
version = "X.Y.Z"
```

### Semver policy

The version is derived from commit types:

| Change | Commit type | Bump |
|---|---|---|
| Any breaking change to a module's inputs or outputs (rename, remove, change a type or default, change a resource name that forces replacement) | `feat!` / `fix!` | major (minor while `0.x`) |
| New module, new optional input, new output | `feat` | minor |
| Behaviour fix that keeps inputs and outputs compatible | `fix` | patch |
| `docs`, `chore`, `ci`, `refactor`, `test`, `style`, `build` | no release on their own |

While the library is on `0.x`, a breaking change bumps the minor version
(`bump-minor-pre-major`). Breaking changes must still be marked `!` so the
changelog calls them out.

## Repository settings

`scripts/apply-repo-settings.sh` applies the settings through the GitHub API:

- Squash and rebase merges only; squash commits use the pull request title and
  a blank body. Head branches are deleted after merge.
- A ruleset on `main` requires a pull request, squash or rebase merges, every
  CI job as a status check and linear history, and blocks force pushes and
  deletion, with no bypass actors.
