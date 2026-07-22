#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/provision-dev-env.yml"
WRITER="$ROOT/scripts/write-environment-values.sh"
failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_pattern() {
  local pattern="$1"
  local description="$2"

  grep -Eq "$pattern" "$WORKFLOW" || fail "missing $description"
}

require_input() {
  local input="$1"

  grep -A 4 -E "^[[:space:]]{6}${input}:" "$WORKFLOW" |
    grep -Eq '^[[:space:]]{8}required:[[:space:]]*true' ||
    fail "workflow_dispatch input $input is not required"
}

[[ -f "$WORKFLOW" ]] || fail "workflow is absent: $WORKFLOW"
[[ -x "$WRITER" ]] || fail "writer script is not executable: $WRITER"

require_pattern 'repository_dispatch:' 'repository_dispatch trigger'
require_pattern 'types:[[:space:]]*\[[[:space:]]*provision-dev-env[[:space:]]*\]' 'provision-dev-env dispatch type'
require_pattern 'workflow_dispatch:' 'workflow_dispatch trigger'
require_pattern 'permissions:[[:space:]]*$' 'permissions block'
require_pattern '^  contents:[[:space:]]*read$' 'read-only default permissions'
require_pattern '^    permissions:$' 'commit job permissions block'
require_pattern '^      contents:[[:space:]]*write$' 'commit job contents write permission'

write_permissions="$(grep -Ec '^[[:space:]]+contents:[[:space:]]*write$' "$WORKFLOW" || true)"
[[ $write_permissions -eq 1 ]] || fail 'contents write permission is granted outside the commit job'

for input in service environment size owner expiration port-run-id; do
  require_pattern "^[[:space:]]{6}${input}:" "workflow_dispatch input $input"
  require_input "$input"
done

for input in service environment size owner expiration; do
  require_pattern "client_payload\.${input}" "repository_dispatch ${input} normalization"
  require_pattern "inputs\.${input}" "workflow_dispatch ${input} normalization"
done

require_pattern "client_payload\['port-run-id'\]" 'repository_dispatch port-run-id normalization'
require_pattern "inputs\['port-run-id'\]" 'workflow_dispatch port-run-id normalization'

require_pattern 'concurrency:' 'per-environment concurrency'
require_pattern '^      group: provision-dev-env-\$\{\{ needs\.normalize\.outputs\.service \}\}-\$\{\{ needs\.normalize\.outputs\.environment \}\}$' 'concurrency based on normalized service and environment'
require_pattern '^      cancel-in-progress:[[:space:]]*false$' 'non-cancelling concurrency'
require_pattern 'ref:[[:space:]]*master' 'master checkout'
require_pattern 'uses: actions/checkout@[0-9a-f]{40}' 'commit-SHA-pinned checkout'
require_pattern 'scripts/write-environment-values\.sh' 'environment values writer invocation'
require_pattern 'git add' 'git add'
require_pattern 'git commit' 'git commit'
require_pattern 'git push.*master' 'push to master'
require_pattern 'values-path' 'values path output'
require_pattern 'commit-sha' 'commit SHA output'
require_pattern 'GITHUB_STEP_SUMMARY' 'job summary'
require_pattern "git config user.email '41898282\\+github-actions\[bot\]@users\.noreply\.github\.com'" 'official GitHub Actions bot email'

for raw_input in RAW_SERVICE RAW_ENVIRONMENT RAW_SIZE RAW_OWNER RAW_EXPIRATION RAW_PORT_RUN_ID; do
  require_pattern 'reject_line_endings "\$'"$raw_input"'"' "CR/LF rejection for $raw_input"
done
require_pattern "\\*\\$'\\\\r'\\*" 'carriage-return rejection'
require_pattern "\\*\\$'\\\\n'\\*" 'line-feed rejection'

last_guard_line="$(grep -n 'reject_line_endings "\$RAW_PORT_RUN_ID"' "$WORKFLOW" | cut -d: -f1 || true)"
first_output_line="$(grep -n -m 1 'GITHUB_OUTPUT' "$WORKFLOW" | cut -d: -f1 || true)"
[[ -n $last_guard_line && -n $first_output_line && $last_guard_line -lt $first_output_line ]] ||
  fail 'line-ending checks do not precede GitHub output writes'

require_pattern '^          for attempt in 1 2 3; do$' 'bounded push retry loop'
require_pattern 'git fetch origin master' 'fetch before retry'
require_pattern 'git rebase origin/master' 'rebase before retry push'
require_pattern 'git rebase --abort' 'safe rebase abort'
require_pattern 'git ls-tree -r --name-only origin/master -- "\$VALUES_PATH"' 'same-environment path conflict detection'

if grep -Eq 'actions/checkout@v[0-9]+' "$WORKFLOW"; then
  fail 'tag-pinned checkout action'
fi

if grep -Eqi '(ghp_|github_pat_|-----BEGIN [A-Z ]*PRIVATE KEY-----)' "$WORKFLOW"; then
  fail 'literal credential or token'
fi

[[ $failures -eq 0 ]] || exit 1

printf 'PASS: provision workflow contract\n'
