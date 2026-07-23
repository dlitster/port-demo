#!/usr/bin/env bash
# Purpose: Configure the read-only Argo CD account used by Port Ocean.
# Phases: Created in Phase 3.1; supports the Argo CD Ocean integration.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
context="kind-portio1"

cd "$repo_root"

# The partial manifest limits forced ownership to the two Ocean account keys.
kubectl --context "$context" apply --server-side --force-conflicts --field-manager=port-demo \
  -f argocd/20-port-ocean-user.yaml
kubectl --context "$context" apply --server-side --field-manager=port-demo \
  -f argocd/21-port-ocean-rbac.yaml
