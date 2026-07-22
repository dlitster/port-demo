# Phase 2 Helm Chart Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and validate a reusable Helm chart that creates one standardized development environment in a namespace.

**Architecture:** The chart owns namespace-scoped quota, limits, RBAC, workload, and optional Service resources. Identity is supplied as values; resource profiles are fixed chart policy.

**Tech Stack:** Helm v4, Kubernetes v1.36, Bash tests, kind `portio1`.

---

### Task 1: Define chart contract

**Files:**
- Create: `charts/development-environment/Chart.yaml`
- Create: `charts/development-environment/values.yaml`
- Create: `charts/development-environment/values.schema.json`
- Test: `tests/test_development_environment_chart.sh`

- [ ] Write a failing shell test that expects `helm lint --strict charts/development-environment` to succeed and an invalid profile to fail.
- [ ] Run `bash tests/test_development_environment_chart.sh` and confirm it fails because the chart is absent.
- [ ] Create a Helm v2 application chart pinned to Kubernetes `>=1.36.0-0 <1.37.0-0`.
- [ ] Define schema-required values for owner, service, RFC 3339 UTC expiration, profile (`small|medium|large`), image, and optional Service ports.
- [ ] Define profile values matching the challenge quota and workload requirements.
- [ ] Re-run the test and confirm the contract passes.

### Task 2: Render environment policy resources

**Files:**
- Create: `charts/development-environment/templates/_helpers.tpl`
- Create: `charts/development-environment/templates/namespace.yaml`
- Create: `charts/development-environment/templates/resourcequota.yaml`
- Create: `charts/development-environment/templates/limitrange.yaml`
- Create: `charts/development-environment/templates/rolebinding.yaml`

- [ ] Extend the test to require Namespace, ResourceQuota, LimitRange, and RoleBinding kinds plus owner/service/profile labels and expiration annotations.
- [ ] Run the test and confirm the resource assertion fails.
- [ ] Render a conditional Namespace using `.Release.Namespace`, quota and LimitRange from the selected profile, and a least-privilege RoleBinding subject supplied by values.
- [ ] Run the test and `helm template dev charts/development-environment --namespace dev-demo --set-string owner=alice --set-string service=checkout-api --set-string expiration=2026-07-23T00:00:00Z --set profile=small`.

### Task 3: Render and deploy sample workload

**Files:**
- Create: `charts/development-environment/templates/deployment.yaml`
- Create: `charts/development-environment/templates/service.yaml`
- Create: `charts/development-environment/README.md`

- [ ] Extend the test to assert Deployment resource requests/limits match each profile and Service rendering is controlled by `httpService.enabled`.
- [ ] Run the test and confirm it fails without workload templates.
- [ ] Implement helpers with stable selectors; never include profile or expiration in a selector.
- [ ] Add a one-replica Deployment and optional ClusterIP Service using a small non-secret HTTP image.
- [ ] Run `helm lint --strict charts/development-environment` and server-side dry-run the rendered manifest against `kind-portio1`.
- [ ] Install a unique test release with `helm upgrade --install --wait`, verify its Deployment is Available, then uninstall it.

### Task 4: Record Phase 2 evidence

**Files:**
- Modify: `implementation-checklist.md`
- Modify: `agentlog/helm-chart.md`

- [ ] Record commands, chart version, profile validation, and direct kind deployment outcome without secrets.
- [ ] Mark Phase 2 complete only after lint, schema failure, server dry-run, install, and uninstall checks pass.
