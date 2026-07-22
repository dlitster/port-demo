#!/usr/bin/env bash
# Purpose: Validate a provisioning request and write deterministic environment values.
# Phases: Created in Phase 4; consumed by the GitHub provisioning workflow.
set -euo pipefail

if [[ $# -ne 6 ]]; then
  printf 'Usage: %s <service> <environment> <size> <owner> <expiration> <port-run-id>\n' "$0" >&2
  exit 1
fi

service=$1
environment=$2
size=$3
owner=$4
expiration=$5
port_run_id=$6

is_dns_safe_name() {
  [[ $1 =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ && ${#1} -le 63 ]]
}

if ! is_dns_safe_name "$service" || ! is_dns_safe_name "$environment" || ! is_dns_safe_name "$owner"; then
  printf 'Service, environment, and owner must be DNS-safe names\n' >&2
  exit 1
fi

if [[ $size != small && $size != medium && $size != large ]]; then
  printf 'Size must be small, medium, or large\n' >&2
  exit 1
fi

if [[ -z $expiration || ! $expiration =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?Z$ ]]; then
  printf 'Expiration must be an RFC3339 UTC timestamp\n' >&2
  exit 1
fi

if ! python3 - "$expiration" <<'PY'
import datetime
import sys

timestamp = sys.argv[1]
calendar_time = timestamp.split('.', 1)[0][:-1]

try:
    datetime.datetime.strptime(calendar_time, '%Y-%m-%dT%H:%M:%S')
except ValueError:
    sys.exit(1)
PY
then
  printf 'Expiration must be a valid RFC3339 UTC timestamp\n' >&2
  exit 1
fi

if [[ -z ${port_run_id//[[:space:]]/} ]]; then
  printf 'Owner, expiration, and Port run ID must not be empty\n' >&2
  exit 1
fi

if [[ $port_run_id =~ [[:cntrl:]] ]]; then
  printf 'Port run ID must not contain control characters\n' >&2
  exit 1
fi

yaml_port_run_id=${port_run_id//\\/\\\\}
yaml_port_run_id=${yaml_port_run_id//\"/\\\"}

service_directory="environments/$service"
environment_directory="$service_directory/$environment"
values_file="$environment_directory/values.yaml"

for directory in environments "$service_directory" "$environment_directory"; do
  if [[ -L $directory ]]; then
    printf 'Refusing symlinked directory %s\n' "$directory" >&2
    exit 1
  fi
done

if [[ -L $values_file ]]; then
  printf 'Refusing symlinked values file %s\n' "$values_file" >&2
  exit 1
fi

if [[ -e $values_file ]]; then
  printf 'Refusing to overwrite %s\n' "$values_file" >&2
  exit 1
fi

mkdir -p "$environment_directory"

cat >"$values_file" <<EOF
owner: $owner
service: $service
expiration: "$expiration"
profile: $size
portRunId: "$yaml_port_run_id"
namespace:
  create: true
EOF
