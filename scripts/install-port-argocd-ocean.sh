#!/usr/bin/env bash
# Purpose: Install the Port Ocean Argo CD integration with local credentials.
# Phases: Created in Phase 3.1 Task 3; installs the Argo CD Ocean integration.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
env_file="$repo_root/.env"
context="kind-portio1"
namespace="port-argocd-integration"
release_name="port-argocd-integration"
credentials_secret="port-argocd-integration-credentials"
argocd_namespace="argocd"
argocd_ca_secret="argocd-server-ca"
chart_version="0.20.2"

if [[ ! -f "$env_file" ]]; then
  printf 'Missing required environment file: %s\n' "$env_file" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$env_file"
set +a

require_credential() {
  local name=$1
  local value=${!name-}

  if [[ -z "$value" || "$value" =~ [[:space:]] ]]; then
    printf '%s must be set in .env and contain no whitespace\n' "$name" >&2
    exit 1
  fi
}

require_credential PORT_CLIENT_ID
require_credential PORT_CLIENT_SECRET
require_credential PORT_BASE_URL
require_credential ARGOCD_TOKEN

if [[ "$PORT_BASE_URL" != "https://api.port.io" ]]; then
  printf 'PORT_BASE_URL must be exactly https://api.port.io\n' >&2
  exit 1
fi

kubectl --context "$context" get node >/dev/null

kubectl --context "$context" create namespace "$namespace" \
  --dry-run=client \
  -o yaml | kubectl --context "$context" apply -f -

kubectl --context "$context" -n "$namespace" create secret generic "$credentials_secret" \
  --from-literal=OCEAN__PORT__CLIENT_ID="$PORT_CLIENT_ID" \
  --from-literal=OCEAN__PORT__CLIENT_SECRET="$PORT_CLIENT_SECRET" \
  --from-literal=OCEAN__INTEGRATION__CONFIG__TOKEN="$ARGOCD_TOKEN" \
  --dry-run=client \
  -o yaml | kubectl --context "$context" apply -f -

argocd_ca_cert=$(kubectl --context "$context" -n "$argocd_namespace" get secret argocd-secret \
  -o jsonpath='{.data.tls\.crt}' | base64 --decode)
if [[ -z "$argocd_ca_cert" ]]; then
  printf 'Argo CD server certificate must be present in argocd-secret data.tls.crt\n' >&2
  exit 1
fi

if ! printf '%s' "$argocd_ca_cert" | openssl x509 -noout >/dev/null; then
  printf 'Argo CD server certificate must be a valid PEM certificate\n' >&2
  exit 1
fi

printf '%s\n' "$argocd_ca_cert" |
  kubectl --context "$context" -n "$namespace" create secret generic "$argocd_ca_secret" \
  --from-file=crt=/dev/stdin \
  --dry-run=client \
  -o yaml | kubectl --context "$context" apply -f -

helm repo add --force-update port-labs https://port-labs.github.io/helm-charts
helm repo update port-labs
helm upgrade --install "$release_name" port-labs/port-ocean \
  --kube-context "$context" \
  --namespace "$namespace" \
  --version "$chart_version" \
  --set secret.create=false \
  --set-string secret.name="$credentials_secret" \
  --set-string integration.identifier=argocd-portio1 \
  --set-string integration.type=argocd \
  --set-string integration.eventListener.type=POLLING \
  --set-string integration.config.serverUrl=https://argocd-server.argocd.svc.cluster.local \
  --set scheduledResyncInterval=120 \
  --set-string port.baseUrl="$PORT_BASE_URL" \
  --set selfSignedCertificate.enabled=true \
  --set selfSignedCertificate.secret.useExistingSecret=true \
  --set-string selfSignedCertificate.secret.name="$argocd_ca_secret" \
  --set-string selfSignedCertificate.secret.key=crt

deployment_names=$(kubectl --context "$context" -n "$namespace" get deployment \
  -l "app.kubernetes.io/instance=$release_name" \
  -o name)
mapfile -t deployments <<< "$deployment_names"
if [[ -z "$deployment_names" ]]; then
  deployments=()
fi

if [[ ${#deployments[@]} -ne 1 ]]; then
  printf 'Expected exactly one Ocean deployment for Helm release %s; found %s\n' \
    "$release_name" "${#deployments[@]}" >&2
  exit 1
fi

kubectl --context "$context" -n "$namespace" rollout restart \
  "${deployments[0]}"
kubectl --context "$context" -n "$namespace" rollout status \
  "${deployments[0]}" \
  --timeout=5m

printf 'Port Ocean Argo CD integration is ready\n'
