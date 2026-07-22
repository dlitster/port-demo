#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary_root=$(mktemp -d)
trap 'rm -rf "$temporary_root"' EXIT

mkdir -p "$temporary_root/scripts"
cp "$repo_root/scripts/install-port-exporter.sh" "$temporary_root/scripts/install-port-exporter.sh"

cat >"$temporary_root/.env" <<'EOF'
PORT_CLIENT_ID=
PORT_CLIENT_SECRET=
PORT_BASE_URL=https://api.port.io
CLUSTER_NAME=portio1
KIND_NODE_IMAGE=kindest/node:v1.36.1
EOF

if (cd "$temporary_root" && bash scripts/install-port-exporter.sh) >"$temporary_root/output" 2>&1; then
  printf 'Expected install-port-exporter.sh to reject empty Port credentials\n' >&2
  exit 1
fi

if ! grep -Fq 'PORT_CLIENT_ID must be set in .env' "$temporary_root/output"; then
  printf 'Expected missing Port client ID error message\n' >&2
  exit 1
fi
