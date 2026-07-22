#!/usr/bin/env bash
# Purpose: Verify the development-environment Helm chart contract and rendered resources.
# Phases: Created in Phase 2; extended in Phase 4 for Port run ID annotations.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
chart="$repo_root/charts/development-environment"
valid_values=(
  --set owner=platform-team
  --set service=payments-api
  --set httpService.enabled=false
  --set expiration=2026-07-22T12:00:00Z
  --set profile=medium
  --set image=registry.example.com/payments-api:1.0.0
  --set namespace.create=true
  --set roleBinding.subjectName=payments-developer
  --set roleBinding.subjectKind=User
)

helm lint --strict "$chart"
helm lint --strict "$chart" "${valid_values[@]}"

if helm lint --strict "$chart" "${valid_values[@]}" --set profile=extra-large; then
  printf 'Expected helm lint to reject an unsupported profile\n' >&2
  exit 1
fi

if helm lint --strict "$chart" "${valid_values[@]}" --set owner='platform/team'; then
  printf 'Expected helm lint to reject an invalid owner label value\n' >&2
  exit 1
fi

if helm lint --strict "$chart" "${valid_values[@]}" --set service='payments_api'; then
  printf 'Expected helm lint to reject an invalid service label value\n' >&2
  exit 1
fi

if helm lint --strict "$chart" "${valid_values[@]}" --set service.name=payments-api; then
  printf 'Expected helm lint to reject the legacy service object\n' >&2
  exit 1
fi

rendered=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}")

helm lint --strict "$chart" "${valid_values[@]}" --set-string portRunId=run-123

rendered_with_port_run_id=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" \
  --set-string portRunId=run-123)

if [[ $(grep -Fxc '    platform.example.com/port-run-id: "run-123"' <<<"$rendered_with_port_run_id") -ne 5 ]]; then
  printf 'Expected Port run ID annotation on every rendered resource\n' >&2
  exit 1
fi

if grep -Fq 'platform.example.com/port-run-id:' <<<"$rendered"; then
  printf 'Expected no blank Port run ID annotation when portRunId is absent\n' >&2
  exit 1
fi

rendered_with_whitespace_port_run_id=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" \
  --set-string 'portRunId=   ')

if grep -Fq 'platform.example.com/port-run-id:' <<<"$rendered_with_whitespace_port_run_id"; then
  printf 'Expected no Port run ID annotation when portRunId is whitespace-only\n' >&2
  exit 1
fi

catalog_service_rendered=$(helm template dev "$chart" --namespace dev-demo \
  --set-string service=checkout-api \
  --set httpService.enabled=true)

if ! grep -qx 'kind: Service' <<<"$catalog_service_rendered"; then
  printf 'Expected catalog service identifier and enabled httpService to template a Service\n' >&2
  exit 1
fi

for kind in Namespace ResourceQuota LimitRange RoleBinding Deployment; do
  if ! grep -qx "kind: $kind" <<<"$rendered"; then
    printf 'Expected rendered manifest to contain kind %s\n' "$kind" >&2
    exit 1
  fi
done

if grep -qx 'kind: Service' <<<"$rendered"; then
  printf 'Expected Service to be omitted when httpService.enabled is false\n' >&2
  exit 1
fi

rendered_with_service=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" \
  --set httpService.enabled=true)

if ! grep -qx 'kind: Service' <<<"$rendered_with_service"; then
  printf 'Expected Service when httpService.enabled is true\n' >&2
  exit 1
fi

rendered_with_nodeport=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" \
  --set httpService.enabled=true \
  --set httpService.type=NodePort)

if ! grep -Fqx '  type: NodePort' <<<"$rendered_with_nodeport"; then
  printf 'Expected Service type override to render NodePort\n' >&2
  exit 1
fi

if ! grep -Fqx '  type: ClusterIP' <<<"$rendered_with_service"; then
  printf 'Expected enabled Service to be ClusterIP\n' >&2
  exit 1
fi

for profile_resource in \
  'small|50m|64Mi|100m|128Mi' \
  'medium|100m|128Mi|200m|256Mi' \
  'large|250m|256Mi|500m|512Mi'; do
  IFS='|' read -r profile request_cpu request_memory limit_cpu limit_memory <<<"$profile_resource"
  profile_rendered=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" --set profile="$profile")
  deployment=$(awk '/^kind: Deployment$/{in_deployment=1} in_deployment{print} /^---$/{if (in_deployment) exit}' <<<"$profile_rendered")

  for expected_value in \
    "              cpu: $request_cpu" \
    "              memory: $request_memory" \
    "              cpu: $limit_cpu" \
    "              memory: $limit_memory"; do
    if ! grep -Fqx "$expected_value" <<<"$deployment"; then
      printf 'Expected Deployment %s profile to contain %s\n' "$profile" "$expected_value" >&2
      exit 1
    fi
  done
done

deployment=$(awk '/^kind: Deployment$/{in_deployment=1} in_deployment{print} /^---$/{if (in_deployment) exit}' <<<"$rendered")

for stable_selector_label in \
  '      app.kubernetes.io/name: "development-environment"' \
  '      app.kubernetes.io/instance: "dev"' \
  '      platform.example.com/owner: "platform-team"' \
  '      platform.example.com/service: "payments-api"'; do
  if ! grep -Fqx "$stable_selector_label" <<<"$deployment"; then
    printf 'Expected Deployment selector to contain stable label %s\n' "$stable_selector_label" >&2
    exit 1
  fi
done

for volatile_selector_value in 'platform.example.com/profile' 'platform.example.com/expires-at'; do
  if grep -Fq "$volatile_selector_value" <<<"$(awk '/^  selector:/{in_selector=1} in_selector{print} /^  template:/{exit}' <<<"$deployment")"; then
    printf 'Expected Deployment selector to exclude %s\n' "$volatile_selector_value" >&2
    exit 1
  fi
done

overridden_policy=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" \
  --set sizeProfiles.medium.namespaceQuota.hard.cpu=99 \
  --set sizeProfiles.medium.workload.requests.cpu=999m \
  --set sizeProfiles.medium.workload.limits.cpu=999m)

for overridden_value in 'cpu: 99' 'cpu: 999m'; do
  if grep -Fq "$overridden_value" <<<"$overridden_policy"; then
    printf 'Expected profile policy to ignore user override %s\n' "$overridden_value" >&2
    exit 1
  fi
done

quoted_subject=$(helm template dev "$chart" --namespace dev-demo "${valid_values[@]}" \
  --set-string 'roleBinding.subjectName=alice: admin')

if ! grep -Fqx '    name: "alice: admin"' <<<"$quoted_subject"; then
  printf 'Expected RoleBinding subject name with colon to be quoted\n' >&2
  exit 1
fi

for metadata in \
  '    platform.example.com/owner: "platform-team"' \
  '    platform.example.com/service: "payments-api"' \
  '    platform.example.com/profile: "medium"' \
  '    platform.example.com/expires-at: "2026-07-22T12:00:00Z"'; do
  if [[ $(grep -Fxc "$metadata" <<<"$rendered") -ne 5 ]]; then
    printf 'Expected %s on every policy and workload resource\n' "$metadata" >&2
    exit 1
  fi
done

if [[ $(grep -Fxc '  namespace: dev-demo' <<<"$rendered") -ne 4 ]]; then
  printf 'Expected all namespaced resources to use the release namespace\n' >&2
  exit 1
fi

for policy_value in \
  '    cpu: "1"' \
  '    memory: 1Gi' \
  '        cpu: 100m' \
  '        memory: 128Mi' \
  '        cpu: 200m' \
  '        memory: 256Mi' \
  '  - kind: User' \
  '    name: "payments-developer"' \
  '  kind: ClusterRole' \
  '  name: view'; do
  if ! grep -Fqx "$policy_value" <<<"$rendered"; then
    printf 'Expected rendered manifest to contain %s\n' "$policy_value" >&2
    exit 1
  fi
done
