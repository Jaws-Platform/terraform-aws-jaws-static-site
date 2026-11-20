#!/usr/bin/env bash
# Lists every Terraform module in this repository: the root module, then each
# directory under modules/ that has a versions.tf (nested ones included).
# Examples and test fixtures are not modules; scripts/check-module.sh checks
# a module's examples together with it.
#
#   scripts/list-modules.sh          one path per line
#   scripts/list-modules.sh --json   the CI matrix: [{"name": ..., "path": ...}]
set -euo pipefail

cd "$(dirname "$0")/.."

paths=(.)
if [[ -d modules ]]; then
  while IFS= read -r dir; do
    paths+=("$dir")
  done < <(
    find modules -name versions.tf \
      -not -path '*/examples/*' -not -path '*/tests/*' -not -path '*/.terraform/*' \
      -exec dirname {} \; | sort
  )
fi

if [[ "${1:-}" != "--json" ]]; then
  printf '%s\n' "${paths[@]}"
  exit 0
fi

json="["
for path in "${paths[@]}"; do
  name="${path#modules/}"
  [[ "$path" == "." ]] && name="root"
  json+="{\"name\":\"${name}\",\"path\":\"${path}\"},"
done
printf '%s]\n' "${json%,}"
