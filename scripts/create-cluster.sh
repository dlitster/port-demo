#!/usr/bin/env bash
# Purpose: Create or verify the dedicated kind cluster used by this demo.
# Phases: Created in Phase 1; reused by all cluster-based phases.
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
: "${KIND_NODE_IMAGE:?KIND_NODE_IMAGE must be set in .env}"

if kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  printf 'kind cluster %s already exists\n' "$CLUSTER_NAME"
else
  kind create cluster \
    --name "$CLUSTER_NAME" \
    --image "$KIND_NODE_IMAGE" \
    --wait 2m
fi

kubectl --context "kind-$CLUSTER_NAME" wait \
  --for=condition=Ready node \
  --all \
  --timeout=2m

printf 'Cluster context ready: kind-%s\n' "$CLUSTER_NAME"
