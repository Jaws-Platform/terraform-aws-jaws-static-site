#!/usr/bin/env bash
# Runs every check CI runs for one module directory, and for its examples:
#
#   terraform init -backend=false, terraform validate, tflint, terraform test,
#   the terraform-docs diff check, and the tests of any script the module
#   ships (files/test_*.py, files/*.sh, tests/test-*.sh).
#
#   scripts/check-module.sh .                  the root module
#   scripts/check-module.sh modules/<name>     one submodule
#
# Nothing here needs cloud credentials: tests use mocked providers.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
dir="${1:?usage: scripts/check-module.sh <module directory>}"

step() { printf '\n==> %s: %s\n' "$dir" "$1"; }

lint() {
  terraform init -backend=false -input=false > /dev/null
  terraform validate
  tflint --config "$root/.tflint.hcl" --format compact
}

cd "$root/$dir"

step "terraform init, validate, tflint"
lint

if compgen -G "tests/*.tftest.hcl" > /dev/null || compgen -G "*.tftest.hcl" > /dev/null; then
  step "terraform test (mocked providers)"
  terraform test
fi

if [[ -f README.md ]] && grep -q 'BEGIN_TF_DOCS' README.md; then
  step "terraform-docs (the README matches the code)"
  terraform-docs --config "$root/.terraform-docs.yml" --output-check .
fi

if compgen -G "files/test_*.py" > /dev/null; then
  step "script unit tests"
  python3 -m unittest discover -s files -p 'test_*.py'
fi

if compgen -G "files/*.sh" > /dev/null; then
  step "shellcheck"
  shellcheck files/*.sh
fi

if compgen -G "tests/test-*.sh" > /dev/null; then
  for script in tests/test-*.sh; do
    step "$script"
    bash "$script"
  done
fi

for example in examples/*/; do
  [[ -f "${example}main.tf" ]] || continue
  step "example ${example%/}"
  (cd "$example" && lint)
done
