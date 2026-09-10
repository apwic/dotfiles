#!/usr/bin/env bash

set -euo pipefail

if [[ ! -f .pre-commit-config.yaml ]]; then
  exit 0
fi

case "$(<.pre-commit-config.yaml)" in
  *"https://github.com/bufbuild/buf"*) ;;
  *) exit 0 ;;
esac

proto_files=()
while IFS= read -r file; do
  case "$file" in
    *.proto) proto_files+=("$file") ;;
  esac
done < <(git diff --cached --name-only --diff-filter=ACMR)

if [[ ${#proto_files[@]} -eq 0 ]]; then
  exit 0
fi

if ! command -v buf >/dev/null 2>&1; then
  echo "buf is required to validate staged proto files" >&2
  exit 1
fi

lint_args=()
for file in "${proto_files[@]}"; do
  lint_args+=(--path "$file")
done

buf lint "${lint_args[@]}"

format_changed=0
for file in "${proto_files[@]}"; do
  if ! buf format "$file" --write --exit-code; then
    format_changed=1
  fi
done

if [[ $format_changed -ne 0 ]]; then
  echo "Buf formatted staged proto files; review and stage them again." >&2
  exit 1
fi
