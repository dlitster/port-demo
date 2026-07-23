#!/usr/bin/env bash
# Purpose: Verify the Argo CD Ocean read-only account manifest contract.
# Phases: Created in Phase 3.1; validates Tasks 1 and 2.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
user_manifest="$repo_root/argocd/20-port-ocean-user.yaml"
rbac_manifest="$repo_root/argocd/21-port-ocean-rbac.yaml"
configurator="$repo_root/scripts/configure-port-argocd-ocean-user.sh"
env_example="$repo_root/.env.example"

require_line() {
  local file=$1
  local expected=$2

  if ! grep -Fqx "$expected" "$file"; then
    printf 'Expected %s to contain: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

reject_line() {
  local file=$1
  local forbidden=$2

  if grep -Fq "$forbidden" "$file"; then
    printf 'Expected %s not to contain: %s\n' "$file" "$forbidden" >&2
    exit 1
  fi
}

for manifest in "$user_manifest" "$rbac_manifest"; do
  if [[ ! -f "$manifest" ]]; then
    printf 'Expected Argo CD Ocean manifest: %s\n' "$manifest" >&2
    exit 1
  fi

  require_line "$manifest" 'apiVersion: v1'
  require_line "$manifest" 'kind: ConfigMap'
  require_line "$manifest" '  namespace: argocd'
  reject_line "$manifest" 'policy.default:'
done

require_line "$user_manifest" '  name: argocd-cm'
require_line "$user_manifest" '  accounts.port-ocean-user: apiKey, login'
require_line "$user_manifest" '  accounts.port-ocean-user.enabled: "true"'
require_line "$rbac_manifest" '  name: argocd-rbac-cm'
require_line "$rbac_manifest" '  policy.port-ocean.csv: |'
reject_line "$rbac_manifest" 'policy.csv:'
reject_line "$rbac_manifest" 'policy.default:'
require_line "$rbac_manifest" '    p, role:read-only-role, applications, get, */*, allow'
require_line "$rbac_manifest" '    p, role:read-only-role, clusters, get, *, allow'
require_line "$rbac_manifest" '    p, role:read-only-role, projects, get, *, allow'
require_line "$rbac_manifest" '    p, role:read-only-role, repositories, get, *, allow'
require_line "$rbac_manifest" '    g, port-ocean-user, role:read-only-role'

if [[ ! -f "$configurator" ]]; then
  printf 'Expected Argo CD Ocean configurator: %s\n' "$configurator" >&2
  exit 1
fi

require_line "$configurator" 'context="kind-portio1"'
require_line "$configurator" '# The partial manifest limits forced ownership to the two Ocean account keys.'
require_line "$configurator" 'kubectl --context "$context" apply --server-side --force-conflicts --field-manager=port-demo \'
require_line "$configurator" '  -f argocd/20-port-ocean-user.yaml'
require_line "$configurator" 'kubectl --context "$context" apply --server-side --field-manager=port-demo \'
require_line "$configurator" '  -f argocd/21-port-ocean-rbac.yaml'
reject_line "$configurator" 'rollout restart'
reject_line "$configurator" 'rollout status'

if [[ $(grep -Fxc 'kubectl --context "$context" apply --server-side --force-conflicts --field-manager=port-demo \' "$configurator") -ne 1 ]]; then
  printf 'Expected configurator to force only the partial Argo CD account ConfigMap fields\n' >&2
  exit 1
fi

if [[ $(grep -Fxc 'kubectl --context "$context" apply --server-side --field-manager=port-demo \' "$configurator") -ne 1 ]]; then
  printf 'Expected configurator to use a non-forced server-side apply for Argo CD RBAC\n' >&2
  exit 1
fi

if [[ ! -f "$env_example" ]]; then
  printf 'Expected local environment template: %s\n' "$env_example" >&2
  exit 1
fi

require_line "$env_example" 'ARGOCD_TOKEN='
