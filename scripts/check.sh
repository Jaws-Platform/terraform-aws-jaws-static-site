#!/usr/bin/env bash
# Runs the whole CI suite locally: formatting, every module (see
# scripts/check-module.sh) and the commit-message tooling. Run it before
# opening a pull request.
#
#   scripts/check.sh                     everything
#   scripts/check.sh modules/<name> ...  only these modules
#
# Requires terraform, tflint, terraform-docs, shellcheck, python3 and node.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

# One provider download shared by every module instead of one per module.
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-$root/.terraform-plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
export TF_IN_AUTOMATION=true

echo "==> terraform fmt"
terraform fmt -check -recursive -diff

echo "==> tflint --init"
tflint --init --config "$root/.tflint.hcl" > /dev/null

if [[ $# -gt 0 ]]; then
  modules=("$@")
else
  modules=()
  while IFS= read -r module; do modules+=("$module"); done < <(scripts/list-modules.sh)
fi

for module in "${modules[@]}"; do
  scripts/check-module.sh "$module"
done

if [[ $# -eq 0 ]]; then
  echo
  echo "==> commit-message tooling"
  [[ -d node_modules ]] || npm ci
  npm test
fi

echo
echo "All checks passed."
