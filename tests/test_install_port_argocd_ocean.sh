#!/usr/bin/env bash
# Purpose: Verify the Port Ocean Argo CD installer contract without credentials.
# Phases: Created in Phase 3.1 Task 3; validates scripts/install-port-argocd-ocean.sh.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
installer="$repo_root/scripts/install-port-argocd-ocean.sh"

require_line() {
  local file=$1
  local expected=$2

  if ! grep -Fqx -- "$expected" "$file"; then
    printf 'Expected %s to contain: %s\n' "$file" "$expected" >&2
    exit 1
  fi
}

reject_pattern() {
  local file=$1
  local forbidden=$2

  if grep -Eq -- "$forbidden" "$file"; then
    printf 'Expected %s not to contain credentials in: %s\n' "$file" "$forbidden" >&2
    exit 1
  fi
}

if [[ ! -f "$installer" ]]; then
  printf 'Expected Port Ocean installer: %s\n' "$installer" >&2
  exit 1
fi

bash -n "$installer"

require_line "$installer" '# Purpose: Install the Port Ocean Argo CD integration with local credentials.'
require_line "$installer" '# Phases: Created in Phase 3.1 Task 3; installs the Argo CD Ocean integration.'
require_line "$installer" 'env_file="$repo_root/.env"'
require_line "$installer" 'source "$env_file"'
require_line "$installer" 'require_credential() {'
require_line "$installer" '  if [[ -z "$value" || "$value" =~ [[:space:]] ]]; then'
require_line "$installer" 'require_credential PORT_CLIENT_ID'
require_line "$installer" 'require_credential PORT_CLIENT_SECRET'
require_line "$installer" 'require_credential PORT_BASE_URL'
require_line "$installer" 'require_credential ARGOCD_TOKEN'
require_line "$installer" 'if [[ "$PORT_BASE_URL" != "https://api.port.io" ]]; then'
require_line "$installer" 'context="kind-portio1"'
require_line "$installer" 'namespace="port-argocd-integration"'
require_line "$installer" 'release_name="port-argocd-integration"'
require_line "$installer" 'credentials_secret="port-argocd-integration-credentials"'
require_line "$installer" 'argocd_namespace="argocd"'
require_line "$installer" 'argocd_ca_secret="argocd-server-ca"'
require_line "$installer" 'chart_version="0.20.2"'
require_line "$installer" '  --from-literal=OCEAN__PORT__CLIENT_ID="$PORT_CLIENT_ID" \'
require_line "$installer" '  --from-literal=OCEAN__PORT__CLIENT_SECRET="$PORT_CLIENT_SECRET" \'
require_line "$installer" '  --from-literal=OCEAN__INTEGRATION__CONFIG__TOKEN="$ARGOCD_TOKEN" \'
require_line "$installer" 'argocd_ca_cert=$(kubectl --context "$context" -n "$argocd_namespace" get secret argocd-secret \'
require_line "$installer" "  -o jsonpath='{.data.tls\\.crt}' | base64 --decode)"
require_line "$installer" 'if [[ -z "$argocd_ca_cert" ]]; then'
require_line "$installer" "if ! printf '%s' \"\$argocd_ca_cert\" | openssl x509 -noout >/dev/null; then"
# Keep PEM delimiters separate when Ocean appends this certificate to its CA bundle.
require_line "$installer" "printf '%s\\n' \"\$argocd_ca_cert\" |"
require_line "$installer" '  kubectl --context "$context" -n "$namespace" create secret generic "$argocd_ca_secret" \'
require_line "$installer" '  --from-file=crt=/dev/stdin \'
require_line "$installer" 'helm repo add --force-update port-labs https://port-labs.github.io/helm-charts'
require_line "$installer" 'helm repo update port-labs'
require_line "$installer" 'helm upgrade --install "$release_name" port-labs/port-ocean \'
require_line "$installer" '  --version "$chart_version" \'
require_line "$installer" '  --set secret.create=false \'
require_line "$installer" '  --set-string secret.name="$credentials_secret" \'
require_line "$installer" '  --set-string integration.identifier=argocd-portio1 \'
require_line "$installer" '  --set-string integration.type=argocd \'
require_line "$installer" '  --set-string integration.eventListener.type=POLLING \'
require_line "$installer" '  --set-string integration.config.serverUrl=https://argocd-server.argocd.svc.cluster.local \'
require_line "$installer" '  --set scheduledResyncInterval=120 \'
require_line "$installer" '  --set-string port.baseUrl="$PORT_BASE_URL" \'
require_line "$installer" '  --set selfSignedCertificate.enabled=true \'
require_line "$installer" '  --set selfSignedCertificate.secret.useExistingSecret=true \'
require_line "$installer" '  --set-string selfSignedCertificate.secret.name="$argocd_ca_secret" \'
require_line "$installer" '  --set-string selfSignedCertificate.secret.key=crt'
require_line "$installer" 'deployment_names=$(kubectl --context "$context" -n "$namespace" get deployment \'
require_line "$installer" '  -l "app.kubernetes.io/instance=$release_name" \'
require_line "$installer" '  -o name)'
require_line "$installer" 'mapfile -t deployments <<< "$deployment_names"'
require_line "$installer" 'if [[ -z "$deployment_names" ]]; then'
require_line "$installer" 'if [[ ${#deployments[@]} -ne 1 ]]; then'
require_line "$installer" 'kubectl --context "$context" -n "$namespace" rollout restart \'
require_line "$installer" '  "${deployments[0]}"'
require_line "$installer" 'kubectl --context "$context" -n "$namespace" rollout status \'
require_line "$installer" '  "${deployments[0]}" \'
require_line "$installer" '  --timeout=5m'

# Values must enter Helm only through the existing Kubernetes Secret.
reject_pattern "$installer" '--set(-string)? .*PORT_CLIENT_(ID|SECRET)'
reject_pattern "$installer" '--set(-string)? .*ARGOCD_TOKEN'
reject_pattern "$installer" '--set(-string)? integration\.secrets\.token'
reject_pattern "$installer" 'integration\.scheduledResyncInterval'
reject_pattern "$installer" 'deployment/"\$release_name"'
reject_pattern "$installer" 'OCEAN__INTEGRATION__SECRETS__TOKEN'
reject_pattern "$installer" 'integration\.config\.sslVerify=false'
reject_pattern "$installer" '--wait'

if [[ $(grep -Fxc '  --timeout=5m' "$installer") -ne 1 ]]; then
  printf 'Expected only the deployment rollout wait to set a timeout\n' >&2
  exit 1
fi

restart_line=$(grep -Fn 'kubectl --context "$context" -n "$namespace" rollout restart \' "$installer" | cut -d: -f1)
status_line=$(grep -Fn 'kubectl --context "$context" -n "$namespace" rollout status \' "$installer" | cut -d: -f1)
timeout_line=$(grep -Fn '  --timeout=5m' "$installer" | cut -d: -f1)
if (( restart_line >= status_line || status_line >= timeout_line )); then
  printf 'Expected deployment restart followed by rollout status and timeout\n' >&2
  exit 1
fi

# Only deployable repository paths are scanned, avoiding ignored .env and documentation examples.
mapfile -t deployable_files < <(git -C "$repo_root" ls-files --cached --others --exclude-standard -- scripts argocd charts .github)
for file in "${deployable_files[@]}"; do
  reject_pattern "$repo_root/$file" '--set(-string)?[[:space:]]+integration\.secrets\.token'
  reject_pattern "$repo_root/$file" '--set(-string)?[[:space:]].*(PORT_CLIENT_SECRET|ARGOCD_TOKEN)'
  reject_pattern "$repo_root/$file" '(PORT_CLIENT_SECRET|ARGOCD_TOKEN)=[^"$[:space:]]'
  reject_pattern "$repo_root/$file" "(PORT_CLIENT_SECRET|ARGOCD_TOKEN)=[[:space:]]*['\"][^\\$]"
  reject_pattern "$repo_root/$file" '--insecure'
done

for phase_doc in \
  "$repo_root/docs/superpowers/plans/2026-07-22-phase-3-1-argocd-ocean.md" \
  "$repo_root/docs/superpowers/specs/2026-07-22-argocd-ocean-integration-design.md"; do
  reject_pattern "$phase_doc" '--insecure'
done

assert_whitespace_credential_rejected() {
  local variable=$1
  local temporary_root

  temporary_root=$(mktemp -d)
  mkdir -p "$temporary_root/bin" "$temporary_root/scripts"
  cp "$installer" "$temporary_root/scripts/install-port-argocd-ocean.sh"
  cat >"$temporary_root/.env" <<'EOF'
PORT_CLIENT_ID=valid-client-id
PORT_CLIENT_SECRET=valid-client-secret
PORT_BASE_URL=https://api.port.io
ARGOCD_TOKEN=valid-argocd-token
EOF
  printf '%s=%q\n' "$variable" '   ' >>"$temporary_root/.env"
  cat >"$temporary_root/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
printf 'kubectl invoked before credential preflight\n' >&2
exit 99
EOF
  chmod +x "$temporary_root/bin/kubectl"

  if (cd "$temporary_root" && PATH="$temporary_root/bin:$PATH" bash scripts/install-port-argocd-ocean.sh) >"$temporary_root/output" 2>&1; then
    printf 'Expected whitespace-only %s to be rejected\n' "$variable" >&2
    rm -rf "$temporary_root"
    exit 1
  fi

  if grep -Fq 'kubectl invoked before credential preflight' "$temporary_root/output"; then
    printf 'Expected whitespace-only %s to be rejected before kubectl\n' "$variable" >&2
    rm -rf "$temporary_root"
    exit 1
  fi

  rm -rf "$temporary_root"
}

for credential in PORT_CLIENT_ID PORT_CLIENT_SECRET PORT_BASE_URL ARGOCD_TOKEN; do
  assert_whitespace_credential_rejected "$credential"
done

rendered_chart=$(mktemp)
token_rendered_chart=$(mktemp)
trap 'rm -f "$rendered_chart" "$token_rendered_chart"' EXIT

helm repo add --force-update port-labs https://port-labs.github.io/helm-charts >/dev/null
helm repo update port-labs >/dev/null
helm template port-argocd-integration port-labs/port-ocean \
  --version 0.20.2 \
  --namespace port-argocd-integration \
  --set secret.create=false \
  --set-string secret.name=render-only-credentials \
  --set-string integration.identifier=argocd-portio1 \
  --set-string integration.type=argocd \
  --set-string integration.eventListener.type=POLLING \
  --set-string integration.config.serverUrl=https://argocd-server.argocd.svc.cluster.local \
  --set scheduledResyncInterval=120 \
  --set-string port.baseUrl=https://api.port.io \
  --set selfSignedCertificate.enabled=true \
  --set selfSignedCertificate.secret.useExistingSecret=true \
  --set-string selfSignedCertificate.secret.name=render-only-ca \
  --set-string selfSignedCertificate.secret.key=crt >"$rendered_chart"

if ! grep -A1 -F 'secretRef:' "$rendered_chart" | grep -Fq 'name: render-only-credentials'; then
  printf 'Expected rendered Ocean deployment to reference the existing secret\n' >&2
  exit 1
fi

if ! grep -Fq 'OCEAN__SCHEDULED_RESYNC_INTERVAL: "120"' "$rendered_chart"; then
  printf 'Expected rendered Ocean configuration to use root scheduledResyncInterval\n' >&2
  exit 1
fi

if ! grep -Fq 'render-only-ca' "$rendered_chart"; then
  printf 'Expected rendered Ocean deployment to reference the existing CA secret\n' >&2
  exit 1
fi

for expected in \
  'name: SSL_CERT_FILE' \
  'name: REQUESTS_CA_BUNDLE' \
  'mountPath: /usr/local/share/ca-certificates/cert.crt' \
  'name: render-only-ca' \
  'key: crt'; do
  if ! grep -Fq "$expected" "$rendered_chart"; then
    printf 'Expected rendered Ocean certificate configuration: %s\n' "$expected" >&2
    exit 1
  fi
done

# This synthetic value verifies the chart maps the integration token to its required key.
helm template port-argocd-integration port-labs/port-ocean \
  --version 0.20.2 \
  --namespace port-argocd-integration \
  --set secret.create=true \
  --set-string integration.secrets.token=render-only-token >"$token_rendered_chart"

if ! grep -A1 -F 'OCEAN__INTEGRATION__CONFIG__TOKEN:' "$token_rendered_chart" | grep -Fq '"cmVuZGVyLW9ubHktdG9rZW4="'; then
  printf 'Expected rendered Ocean secret to map integration.secrets.token to the CONFIG key\n' >&2
  exit 1
fi

if grep -Fq 'OCEAN__INTEGRATION__SECRETS__TOKEN' "$token_rendered_chart"; then
  printf 'Expected rendered Ocean secret not to use the incorrect SECRETS token key\n' >&2
  exit 1
fi
