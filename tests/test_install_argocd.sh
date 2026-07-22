#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
installer="$repo_root/scripts/install-argocd.sh"

if [[ ! -f "$installer" ]]; then
  printf 'Expected Argo CD installer: %s\n' "$installer" >&2
  exit 1
fi

if ! grep -Fq 'context="kind-portio1"' "$installer"; then
  printf 'Expected installer to target kind-portio1\n' >&2
  exit 1
fi

if ! grep -Fq 'argocd_version="v3.4.5"' "$installer"; then
  printf 'Expected installer to pin Argo CD v3.4.5\n' >&2
  exit 1
fi

if ! grep -Fq 'kubectl --context "$context" apply --server-side' "$installer"; then
  printf 'Expected installer to use server-side apply\n' >&2
  exit 1
fi

if ! grep -Fq -- '--namespace "$namespace"' "$installer"; then
  printf 'Expected installer to target the argocd namespace\n' >&2
  exit 1
fi

for workload in \
  'deployment/argocd-server' \
  'deployment/argocd-repo-server' \
  'statefulset/argocd-application-controller' \
  'deployment/argocd-applicationset-controller'; do
  if ! grep -Fq "$workload" "$installer"; then
    printf 'Expected installer to wait for %s\n' "$workload" >&2
    exit 1
  fi
done

if ! grep -Fq 'rollout status "$workload"' "$installer"; then
  printf 'Expected installer to wait for each Argo CD workload\n' >&2
  exit 1
fi

if ! grep -Fq 'get crd applicationsets.argoproj.io' "$installer"; then
  printf 'Expected installer to verify the ApplicationSet CRD\n' >&2
  exit 1
fi
