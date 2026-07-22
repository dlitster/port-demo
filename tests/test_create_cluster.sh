#!/usr/bin/env bash
# Purpose: Verify cluster creation fails safely when required local configuration is absent.
# Phases: Created in Phase 1; validates scripts/create-cluster.sh.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT

mkdir -p "$temporary_root/scripts"
cp "$repo_root/scripts/create-cluster.sh" "$temporary_root/scripts/create-cluster.sh"

if (cd "$temporary_root" && bash scripts/create-cluster.sh) >"$temporary_root/output" 2>&1; then
  printf 'Expected create-cluster.sh to reject a missing .env file\n' >&2
  exit 1
fi

if ! grep -Fq 'Missing required environment file' "$temporary_root/output"; then
  printf 'Expected missing .env error message\n' >&2
  exit 1
fi
