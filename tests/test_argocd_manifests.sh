#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
project="$repo_root/argocd/00-development-environments-project.yaml"
applicationset="$repo_root/argocd/10-development-environments-applicationset.yaml"
canonical_repo='https://github.com/dlitster/port-demo.git'

require_line() {
  local file=$1
  local expected=$2

  if ! grep -Fqx "$expected" "$file"; then
    printf 'Expected %s to contain: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

if [[ ! -f "$project" ]]; then
  printf 'Expected AppProject manifest: %s\n' "$project" >&2
  exit 1
fi

if [[ ! -f "$applicationset" ]]; then
  printf 'Expected ApplicationSet manifest: %s\n' "$applicationset" >&2
  exit 1
fi

require_line "$project" 'kind: AppProject'
require_line "$project" '  name: development-environments'
require_line "$project" "    - $canonical_repo"
require_line "$project" "    - server: https://kubernetes.default.svc"
require_line "$project" "      namespace: 'dev-*'"

for kind in Namespace ResourceQuota LimitRange RoleBinding Deployment Service; do
  require_line "$project" "      kind: $kind"
done

if [[ $(grep -Fxc '    - server: https://kubernetes.default.svc' "$project") -ne 1 ]]; then
  printf 'Expected AppProject to allow only the in-cluster destination server\n' >&2
  exit 1
fi

if [[ $(grep -Fxc "    - $canonical_repo" "$project") -ne 1 || $(grep -Fc '    - https://' "$project") -ne 1 ]]; then
  printf 'Expected AppProject to allow only the canonical source repository\n' >&2
  exit 1
fi

require_line "$applicationset" 'kind: ApplicationSet'
require_line "$applicationset" '  name: development-environments'
require_line "$applicationset" '  goTemplate: true'
require_line "$applicationset" '    - missingkey=error'
require_line "$applicationset" '          - path: environments/*/*'
require_line "$applicationset" '      project: development-environments'
require_line "$applicationset" '        path: charts/development-environment'
require_line "$applicationset" '            - ../../{{.path.path}}/values.yaml'
require_line "$applicationset" '        server: https://kubernetes.default.svc'
require_line "$applicationset" '        namespace: dev-{{index .path.segments 1}}'
require_line "$applicationset" '        automated:'
require_line "$applicationset" '          prune: true'
require_line "$applicationset" '          selfHeal: true'
require_line "$applicationset" '          - CreateNamespace=true'

if [[ $(grep -Fxc "        repoURL: $canonical_repo" "$applicationset") -ne 2 ]]; then
  printf 'Expected generator and Application source to use only the canonical repository\n' >&2
  exit 1
fi

if [[ $(grep -Fc 'repoURL:' "$applicationset") -ne 2 ]]; then
  printf 'Expected ApplicationSet to contain no additional repository sources\n' >&2
  exit 1
fi

if [[ -e "$repo_root/argocd-applicationset.yaml" ]]; then
  printf 'Expected conflicting exploratory root ApplicationSet to be removed\n' >&2
  exit 1
fi

overlay="$repo_root/environments/checkout-api/dev/values.yaml"
if [[ ! -f "$overlay" ]]; then
  printf 'Expected sample overlay: %s\n' "$overlay" >&2
  exit 1
fi

require_line "$overlay" 'owner: platform-team'
require_line "$overlay" 'service: checkout-api'
