# Contributing

`terraform-aws-jaws-static-site` is a versioned Terraform module library, published on the
[Terraform Registry](https://registry.terraform.io/modules/jwallace145/jaws-static-site/aws/latest)
as `jwallace145/jaws-static-site/aws`. It holds no state and deploys nothing: it only publishes
modules. Coding agents should read [AGENTS.md](AGENTS.md).

## Local development setup

Requirements: Terraform `>= 1.11`, [tflint](https://github.com/terraform-linters/tflint),
[terraform-docs](https://terraform-docs.io), [shellcheck](https://www.shellcheck.net),
Python 3, Node.js 24, [pre-commit](https://pre-commit.com) and the GitHub CLI
(`gh`).

```sh
git clone https://github.com/jwallace145/terraform-aws-jaws-static-site.git
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

Each commit message is a **single-line** Conventional Commit:

```
type(scope)?: subject
```

- At most 100 characters.
- Allowed types: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`, `build`,
  `perf`, `style`, `test`, `revert`.
- Breaking changes are marked with `!`, for example `feat!: rename output`.
- The **only** content allowed after the header is a blank line followed by
  `Co-authored-by: Name <email>` trailers. No body text. Details belong in the
  pull request description.

commitlint enforces this (`@commitlint/config-conventional` plus the local
`only-coauthor-trailers` rule in `tools/commitlint/`). The fixtures in
`tests/commitlint/` show accepted and rejected messages; CI checks them.

## Pull requests

- After the initial scaffold commit, **every change reaches `main` through a
  pull request**. Direct pushes are blocked.
- Merges are **squash or rebase only**. No merge commits; history is linear.
- The **title must be a valid Conventional Commit**, because a squash merge
  uses it as the commit message.
- Use the typed template for your change and fill in every section:

  ```sh
  gh pr create --template feat.md      # or fix.md, docs.md, chore.md, refactor.md, ci.md
  ```

  In the browser, append `?template=<type>.md` to the compare URL. `fix.md`
  also asks for Bug, Root cause and Reproduction.

CI runs these jobs on every pull request, and all of them are required on
`main`:

| Job | Checks |
|---|---|
| `commitlint` | Every commit in the range `base..head`, so rebase-merged commits are all checked |
| `pr-title` | The title is a Conventional Commit and passes the commit header rules |
| `commitlint-rules` | Unit tests for the local rule, and the fixture messages |
| `fmt` | `terraform fmt -check -recursive` |
| `terraform` | Every module passed its `terraform (<module>)` job: `init -backend=false`, `validate`, `tflint`, `terraform test`, the terraform-docs diff, the tests of any script the module ships, and the module's examples |

The module list is discovered from the tree (`scripts/list-modules.sh`), so
adding a module needs no workflow change.

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
  release pull request authored by `jwallace145-release-bot[bot]`. CI runs on
  it like any other pull request.
- **Merging the Release Please pull request is the deliberate, human-reviewed
  act that releases a version.** Nobody creates tags by hand.
- The Terraform Registry picks up every tag and publishes it as
  [`jwallace145/jaws-static-site/aws`](https://registry.terraform.io/modules/jwallace145/jaws-static-site/aws/latest).
  Nothing in CI publishes.
- Usage snippets in the READMEs and examples pin the current version on lines
  marked `# x-release-please-version`, which Release Please rewrites.

Consumers pin a version:

```hcl
source  = "jwallace145/jaws-static-site/aws//modules/<name>"
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
