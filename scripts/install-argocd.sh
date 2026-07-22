#!/usr/bin/env bash
set -euo pipefail

context="kind-portio1"
namespace="argocd"
argocd_version="v3.4.5"
manifest_url="https://raw.githubusercontent.com/argoproj/argo-cd/${argocd_version}/manifests/install.yaml"

kubectl --context "$context" get node >/dev/null

kubectl --context "$context" create namespace "$namespace" \
  --dry-run=client \
  -o yaml | kubectl --context "$context" apply --server-side --field-manager=port-demo -f -

kubectl --context "$context" apply --server-side --force-conflicts \
  --field-manager=port-demo \
  --namespace "$namespace" \
  -f "$manifest_url"

for workload in \
  'deployment/argocd-server' \
  'deployment/argocd-repo-server' \
  'statefulset/argocd-application-controller' \
  'deployment/argocd-applicationset-controller'; do
  kubectl --context "$context" --namespace "$namespace" rollout status "$workload" --timeout=5m
done

kubectl --context "$context" get crd applicationsets.argoproj.io >/dev/null

printf 'Argo CD %s is ready in namespace %s on %s\n' "$argocd_version" "$namespace" "$context"
