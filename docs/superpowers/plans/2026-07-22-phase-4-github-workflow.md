# Phase 4 GitHub Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a GitHub Actions workflow that safely commits one environment values file per provisioning request.

**Architecture:** A single writer validates six explicit inputs, refuses existing paths, writes deterministic YAML, and pushes one commit to `master`. ApplicationSet consumes that commit.

**Tech Stack:** GitHub Actions, Bash, Git, Helm values YAML.

---

### Task 1: Build input writer with tests

**Files:**
- Create: `scripts/write-environment-values.sh`
- Create: `tests/test_write_environment_values.sh`

- [ ] Write failing tests for invalid DNS-safe service/environment names, invalid size, missing owner/expiration/run ID, duplicate path, and successful exact YAML.
- [ ] Run the test and confirm failure because the writer is absent.
- [ ] Implement explicit arguments: service, environment name, size, owner, expiration date, and Port run ID.
- [ ] Restrict size to `small`, `medium`, or `large`; preserve an existing values file byte-for-byte on duplicate input.
- [ ] Run the test until all cases pass.

### Task 2: Add dispatch workflow

**Files:**
- Create: `.github/workflows/provision-dev-env.yml`
- Test: `tests/test_provision_workflow.sh`

- [ ] Write a failing test requiring `repository_dispatch` type `provision-dev-env`, matching `workflow_dispatch` inputs, `contents: write`, and per-environment concurrency.
- [ ] Implement checkout of `master`, writer invocation, commit, push, GitHub step outputs, and job summary.
- [ ] Run shell tests plus `actionlint` if available.
- [ ] Manually dispatch a unique test environment after the repository remote exists, then dispatch the same inputs to prove duplicate refusal.

### Task 3: Record Phase 4 evidence

**Files:**
- Modify: `implementation-checklist.md`
- Modify: `agentlog/github-workflow.md`

- [ ] Record the test path, commit SHA, workflow URL, and duplicate-rejection result without tokens.
