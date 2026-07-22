#!/usr/bin/env bash
# Purpose: Verify provisioning input validation, safe file creation, and chart-compatible YAML.
# Phases: Created in Phase 4; validates scripts/write-environment-values.sh.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
writer="$repo_root/scripts/write-environment-values.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

assert_fails() {
  local description=$1
  shift

  if "$@" >"$workdir/stdout" 2>"$workdir/stderr"; then
    printf 'Expected %s to fail\n' "$description" >&2
    exit 1
  fi
}

assert_file_equals() {
  local expected=$1
  local actual=$2

  if ! cmp -s "$expected" "$actual"; then
    printf 'Expected %s to exactly match %s\n' "$actual" "$expected" >&2
    exit 1
  fi
}

run_writer() {
  (
    cd "$1"
    shift
    "$writer" "$@"
  )
}

run_writer_without_date() {
  (
    cd "$1"
    shift
    PATH="$workdir/no-date:$PATH" "$writer" "$@"
  )
}

for args in \
  '' \
  'checkout-api dev medium platform-team 2026-07-22T12:00:00Z' \
  'checkout-api dev medium platform-team 2026-07-22T12:00:00Z run-123 extra'; do
  read -r -a split_args <<<"$args"
  assert_fails "an invalid argument count" run_writer "$workdir" "${split_args[@]}"
done

for invalid_service in Checkout-api checkout_api -checkout checkout-; do
  assert_fails "an invalid service label" run_writer "$workdir" "$invalid_service" dev medium platform-team 2026-07-22T12:00:00Z run-123
done

for invalid_environment in Dev dev_env -dev dev-; do
  assert_fails "an invalid environment label" run_writer "$workdir" checkout-api "$invalid_environment" medium platform-team 2026-07-22T12:00:00Z run-123
done

invalid_owner_too_long=$(printf 'a%.0s' {1..64})
for invalid_owner in Platform-team platform_team -platform platform- "$invalid_owner_too_long"; do
  assert_fails "an invalid owner label" run_writer "$workdir" checkout-api dev medium "$invalid_owner" 2026-07-22T12:00:00Z run-123
done

for invalid_size in '' tiny xlarge; do
  assert_fails "an invalid size" run_writer "$workdir" checkout-api dev "$invalid_size" platform-team 2026-07-22T12:00:00Z run-123
done

assert_fails "an empty owner" run_writer "$workdir" checkout-api dev medium '' 2026-07-22T12:00:00Z run-123
assert_fails "an empty expiration" run_writer "$workdir" checkout-api dev medium platform-team '' run-123
for invalid_expiration in 2026-07-22 2026-07-22T12:00:00+00:00 2026-07-22T12:00Z 2026-99-99T99:99:99Z 2026-02-29T12:00:00Z; do
  assert_fails "an invalid expiration" run_writer "$workdir" checkout-api dev medium platform-team "$invalid_expiration" run-123
done
assert_fails "an empty Port run ID" run_writer "$workdir" checkout-api dev medium platform-team 2026-07-22T12:00:00Z ''
assert_fails "a whitespace-only Port run ID" run_writer "$workdir" checkout-api dev medium platform-team 2026-07-22T12:00:00Z '   '
for invalid_port_run_id in $'run\n123' $'run\t123' $'run\r123' $'run\v123' $'run\001123'; do
  rm -rf "$workdir/environments/checkout-api/control"
  assert_fails "a Port run ID with control characters" run_writer "$workdir" checkout-api control medium platform-team 2026-07-22T12:00:00Z "$invalid_port_run_id"
done

mkdir -p "$workdir/environments/checkout-api/dev"
printf 'preserve these bytes\n' >"$workdir/environments/checkout-api/dev/values.yaml"
cp "$workdir/environments/checkout-api/dev/values.yaml" "$workdir/original-values.yaml"
assert_fails "an existing values file" run_writer "$workdir" checkout-api dev medium platform-team 2026-07-22T12:00:00Z run-123
assert_file_equals "$workdir/original-values.yaml" "$workdir/environments/checkout-api/dev/values.yaml"

outside_directory="$workdir/outside"
mkdir -p "$outside_directory"
ln -s "$outside_directory" "$workdir/environments/checkout-api/linked"

if run_writer "$workdir" checkout-api linked medium platform-team 2026-07-22T12:00:00Z run-123; then
  writer_followed_environment_symlink=true
else
  writer_followed_environment_symlink=false
fi

if [[ -e "$outside_directory/values.yaml" ]]; then
  printf 'Expected writer not to create values.yaml outside the repository\n' >&2
  exit 1
fi

if [[ $writer_followed_environment_symlink == true ]]; then
  printf 'Expected a symlinked environment directory to fail\n' >&2
  exit 1
fi

outside_values_file="$workdir/outside-dangling-values.yaml"
mkdir -p "$workdir/environments/checkout-api/dangling"
ln -s "$outside_values_file" "$workdir/environments/checkout-api/dangling/values.yaml"

if run_writer "$workdir" checkout-api dangling medium platform-team 2026-07-22T12:00:00Z run-123; then
  writer_followed_values_symlink=true
else
  writer_followed_values_symlink=false
fi

if [[ -e $outside_values_file ]]; then
  printf 'Expected writer not to create a dangling values.yaml symlink target outside the repository\n' >&2
  exit 1
fi

if [[ $writer_followed_values_symlink == true ]]; then
  printf 'Expected a dangling values.yaml symlink to fail\n' >&2
  exit 1
fi

rm -rf "$workdir/environments"

mkdir -p "$workdir/no-date"
cat >"$workdir/no-date/date" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x "$workdir/no-date/date"

if ! run_writer_without_date "$workdir" checkout-api leap-day medium request-team 2024-02-29T12:00:00Z leap-run; then
  printf 'Expected valid leap-day expiration without date command\n' >&2
  exit 1
fi

run_writer "$workdir" checkout-api quoted medium platform-team 2026-07-22T12:00:00Z true

if ! grep -Fqx 'portRunId: "true"' "$workdir/environments/checkout-api/quoted/values.yaml"; then
  printf 'Expected bool-like Port run ID to be written as a YAML string\n' >&2
  exit 1
fi

helm lint --strict "$repo_root/charts/development-environment" -f "$workdir/environments/checkout-api/quoted/values.yaml"

run_writer "$workdir" checkout-api escaped medium platform-team 2026-07-22T12:00:00Z 'run"\id'
helm lint --strict "$repo_root/charts/development-environment" -f "$workdir/environments/checkout-api/escaped/values.yaml"

run_writer "$workdir" checkout-api dev medium request-team 2026-07-22T12:00:00Z run-123

cat >"$workdir/expected-values.yaml" <<'EOF'
owner: request-team
service: checkout-api
expiration: "2026-07-22T12:00:00Z"
profile: medium
portRunId: "run-123"
namespace:
  create: true
EOF
assert_file_equals "$workdir/expected-values.yaml" "$workdir/environments/checkout-api/dev/values.yaml"

cp -a "$repo_root" "$workdir/repo"
cp "$workdir/environments/checkout-api/dev/values.yaml" "$workdir/repo/environments/checkout-api/dev/values.yaml"
helm lint --strict "$workdir/repo/charts/development-environment" -f "$workdir/repo/environments/checkout-api/dev/values.yaml"
helm template dev-checkout-api "$workdir/repo/charts/development-environment" \
  --namespace dev-dev \
  -f "$workdir/repo/environments/checkout-api/dev/values.yaml" >"$workdir/rendered.yaml"

for requested_value in \
  '    platform.example.com/owner: "request-team"' \
  '    platform.example.com/service: "checkout-api"' \
  '    platform.example.com/profile: "medium"' \
  '    platform.example.com/expires-at: "2026-07-22T12:00:00Z"' \
  '    platform.example.com/port-run-id: "run-123"'; do
  if [[ $(grep -Fxc "$requested_value" "$workdir/rendered.yaml") -ne 5 ]]; then
    printf 'Expected rendered resources to use requested value %s\n' "$requested_value" >&2
    exit 1
  fi
done
