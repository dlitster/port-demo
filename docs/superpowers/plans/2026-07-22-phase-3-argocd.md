# Phase 3 Argo CD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Have Argo CD discover `environments/*/*` and deploy the shared Helm chart to `portio1`.

**Architecture:** A constrained AppProject and Git-directory ApplicationSet generate one Application per environment directory. Repository credentials live in Argo CD, never in Git.

**Tech Stack:** Argo CD, ApplicationSet, Helm, kind, GitHub.

---

### Task 1: Establish GitOps prerequisites

**Files:**
- Create: `README.md`
- Modify: `agentlog/argocd.md`

- [ ] Create the first `master` commit and configure a Git remote.
- [ ] Document the selected repository URL and whether it is public or requires an Argo CD deploy key/GitHub App credential.
- [ ] Confirm Phase 2 chart and one committed `environments/<service>/<environment>/values.yaml` exist.
- [ ] Stop and request the repository credential/UI step if Argo CD cannot clone the remote.

### Task 2: Install pinned Argo CD on portio1

**Files:**
- Create: `scripts/install-argocd.sh`
- Create: `tests/test_install_argocd.sh`

- [ ] Write a failing test asserting the script pins an Argo CD chart/version and targets `kind-portio1`.
- [ ] Implement the installer and wait for server, repo-server, application-controller, and applicationset-controller deployments.
- [ ] Run the test and `kubectl --context kind-portio1 get pods -n argocd` to verify Ready pods.

### Task 3: Add project and ApplicationSet

**Files:**
- Create: `argocd/00-development-environments-project.yaml`
- Create: `argocd/10-development-environments-applicationset.yaml`
- Test: `tests/test_argocd_manifests.sh`

- [ ] Write a failing manifest test requiring source repo restriction, destination `https://kubernetes.default.svc`, `dev-*` namespaces, and directory generator `environments/*/*`.
- [ ] Implement AppProject allow-lists matching Phase 2 resource kinds.
- [ ] Implement ApplicationSet with automated sync, prune, self-heal, `CreateNamespace=true`, and `missingkey=error`.
- [ ] Apply manifests and verify exactly one generated Application for the sample environment is Synced and Healthy.

### Task 4: Record Phase 3 evidence

**Files:**
- Modify: `implementation-checklist.md`
- Modify: `agentlog/argocd.md`

- [ ] Record repository access method, pinned version, generated Application name, namespace, and sync result.
