#!/usr/bin/env bash
# Purpose: Install the Port Kubernetes exporter with local credentials.
# Phases: Created in Phase 1; supports catalog ingestion for Phases 5 and 6.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file="$repo_root/.env"
namespace="port-k8s-exporter"
release_name="port-k8s-exporter"
credentials_secret="port-k8s-exporter-credentials"
chart_version="0.3.28"

if [[ ! -f "$env_file" ]]; then
  printf 'Missing required environment file: %s\n' "$env_file" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$env_file"
set +a

: "${PORT_CLIENT_ID:?PORT_CLIENT_ID must be set in .env}"
: "${PORT_CLIENT_SECRET:?PORT_CLIENT_SECRET must be set in .env}"
: "${PORT_BASE_URL:?PORT_BASE_URL must be set in .env}"
: "${CLUSTER_NAME:?CLUSTER_NAME must be set in .env}"

context="kind-$CLUSTER_NAME"
kubectl --context "$context" get node >/dev/null

kubectl --context "$context" create namespace "$namespace" \
  --dry-run=client \
  -o yaml | kubectl --context "$context" apply -f -

kubectl --context "$context" -n "$namespace" create secret generic "$credentials_secret" \
  --from-literal=PORT_CLIENT_ID="$PORT_CLIENT_ID" \
  --from-literal=PORT_CLIENT_SECRET="$PORT_CLIENT_SECRET" \
  --dry-run=client \
  -o yaml | kubectl --context "$context" apply -f -

helm repo add --force-update port-labs https://port-labs.github.io/helm-charts
helm repo update port-labs
helm upgrade --install "$release_name" port-labs/port-k8s-exporter \
  --kube-context "$context" \
  --namespace "$namespace" \
  --version "$chart_version" \
  --set secret.useExistingSecret=true \
  --set-string secret.name="$credentials_secret" \
  --set-string portBaseUrl="$PORT_BASE_URL" \
  --set-string stateKey="$CLUSTER_NAME-k8s-exporter" \
  --set extraEnv[0].name=CLUSTER_NAME \
  --set-string extraEnv[0].value="$CLUSTER_NAME" \
  --wait \
  --timeout 5m

kubectl --context "$context" -n "$namespace" rollout status \
  deployment/"$release_name" \
  --timeout=5m

printf 'Port Kubernetes exporter is ready for cluster %s\n' "$CLUSTER_NAME"
