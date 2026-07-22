#!/usr/bin/env bash
# Purpose: Remove the dedicated kind cluster used by this demo.
# Phases: Created in Phase 1; supports cleanup for all cluster-based phases.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file="$repo_root/.env"

if [[ ! -f "$env_file" ]]; then
  printf 'Missing required environment file: %s\n' "$env_file" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$env_file"
set +a

: "${CLUSTER_NAME:?CLUSTER_NAME must be set in .env}"

if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  kind delete cluster --name "$CLUSTER_NAME"
else
  printf 'kind cluster %s does not exist\n' "$CLUSTER_NAME"
fi
