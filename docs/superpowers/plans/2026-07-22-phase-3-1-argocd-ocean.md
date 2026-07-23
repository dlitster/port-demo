# Argo CD Ocean Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the Port Ocean Argo CD integration in `kind-portio1` using a dedicated read-only Argo CD user and local-only credentials.

**Architecture:** Git-tracked partial ConfigMaps create the Argo CD account and additive `policy.port-ocean.csv` RBAC policy through server-side apply. A local installer reads ignored `.env`, creates the Ocean credential Secret and an in-memory copy of the Argo CD server CA, and installs pinned Ocean chart `0.20.2` with those existing secrets. Ocean polls the Argo CD service through its in-cluster HTTPS address and sends data to `https://api.port.io`.

**Tech Stack:** Kubernetes, Argo CD v3.4.5, Argo CD CLI, Helm, Port Ocean 0.20.2, Bash, Port EU MCP.

---

### Task 1: Define and validate the Argo CD account contract

**Files:**
- Create: `argocd/20-port-ocean-user.yaml`
- Create: `argocd/21-port-ocean-rbac.yaml`
- Create: `tests/test_argocd_ocean_manifests.sh`

- [ ] **Step 1: Write the failing manifest test**

Create `tests/test_argocd_ocean_manifests.sh` with assertions for both expected manifest paths and these exact lines:

```bash
require_line "$user_manifest" '  accounts.port-ocean-user: apiKey, login'
require_line "$user_manifest" '  accounts.port-ocean-user.enabled: "true"'
require_line "$rbac_manifest" '    p, role:read-only-role, applications, get, */*, allow'
require_line "$rbac_manifest" '    p, role:read-only-role, clusters, get, *, allow'
require_line "$rbac_manifest" '    p, role:read-only-role, projects, get, *, allow'
require_line "$rbac_manifest" '    p, role:read-only-role, repositories, get, *, allow'
require_line "$rbac_manifest" '    g, port-ocean-user, role:read-only-role'
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test_argocd_ocean_manifests.sh`

Expected: failure because the account manifests do not exist.

- [ ] **Step 3: Add partial ConfigMap manifests**

Create `argocd/20-port-ocean-user.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  accounts.port-ocean-user: apiKey, login
  accounts.port-ocean-user.enabled: "true"
```

Create `argocd/21-port-ocean-rbac.yaml` with composable `policy.port-ocean.csv` containing the five tested policy lines. Do not set `policy.csv` or `policy.default`; the cluster's existing RBAC policies must remain untouched.

- [ ] **Step 4: Verify manifest contract and server-side validation**

Run:

```bash
bash tests/test_argocd_ocean_manifests.sh
kubectl --context kind-portio1 apply --server-side --dry-run=server -f argocd/20-port-ocean-user.yaml
kubectl --context kind-portio1 apply --server-side --dry-run=server -f argocd/21-port-ocean-rbac.yaml
```

Expected: all commands exit zero.

### Task 2: Configure the dedicated user and local secret contract

**Files:**
- Create: `scripts/configure-port-argocd-ocean-user.sh`
- Modify: `.env.example`
- Modify: `tests/test_argocd_ocean_manifests.sh`

- [ ] **Step 1: Extend the test with installer assertions**

Require `scripts/configure-port-argocd-ocean-user.sh` to use `kind-portio1`, server-side apply, and both account manifest paths without a forced Argo CD restart or rollout wait.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test_argocd_ocean_manifests.sh`

Expected: failure because the configurator is absent.

- [ ] **Step 3: Implement the configurator and document the local token variable**

Implement the script with this behavior:

```bash
kubectl --context kind-portio1 apply --server-side --field-manager=port-demo \
  -f argocd/20-port-ocean-user.yaml
kubectl --context kind-portio1 apply --server-side --field-manager=port-demo \
  -f argocd/21-port-ocean-rbac.yaml
```

Argo CD observes ConfigMap changes; no forced `argocd-server` restart or rollout wait is required.

Append only the blank placeholder `ARGOCD_TOKEN=` to `.env.example`.

- [ ] **Step 4: Create the API token without exposing it to automation logs**

After applying the account configuration, an operator runs a local port-forward and CLI login, then writes the generated token directly to ignored `.env` as `ARGOCD_TOKEN`. Do not capture the token in test output, Git, agent logs, or chat output.

```bash
kubectl --context kind-portio1 -n argocd port-forward svc/argocd-server 8080:80
argocd login localhost:8080 --username admin --plaintext
argocd account generate-token --account port-ocean-user
```

- [ ] **Step 5: Re-run the contract test**

Run: `bash tests/test_argocd_ocean_manifests.sh`

Expected: exit zero.

### Task 3: Install Ocean from local credentials

**Files:**
- Create: `scripts/install-port-argocd-ocean.sh`
- Create: `tests/test_install_port_argocd_ocean.sh`

- [ ] **Step 1: Write the failing installer test**

Require the installer to source root `.env`, validate `PORT_CLIENT_ID`, `PORT_CLIENT_SECRET`, `PORT_BASE_URL`, and `ARGOCD_TOKEN`, target `kind-portio1`, create secret `port-argocd-integration-credentials`, use `secret.create=false` with `secret.name=port-argocd-integration-credentials`, pin `port-ocean` to `0.20.2`, and set these non-secret integration values:

```text
integration.identifier=argocd-portio1
integration.type=argocd
integration.eventListener.type=POLLING
integration.config.serverUrl=https://argocd-server.argocd.svc.cluster.local
scheduledResyncInterval=120 (root chart value, not under `integration`)
port.baseUrl=$PORT_BASE_URL
```

The test must reject literal `PORT_CLIENT_SECRET`, `ARGOCD_TOKEN`, and `--set integration.secrets.token` values in repository files.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test_install_port_argocd_ocean.sh`

Expected: failure because the installer is absent.

- [ ] **Step 3: Implement secret creation and pinned Helm install**

Create/update the namespace and credential Secret with client-side dry-run YAML piped to `kubectl apply`; use these secret keys:

```bash
--from-literal=OCEAN__PORT__CLIENT_ID="$PORT_CLIENT_ID"
--from-literal=OCEAN__PORT__CLIENT_SECRET="$PORT_CLIENT_SECRET"
--from-literal=OCEAN__INTEGRATION__CONFIG__TOKEN="$ARGOCD_TOKEN"
```

Stream `argocd-secret`'s `tls.crt` data directly into `argocd-server-ca` under the `crt` key in the Ocean namespace. Configure the chart to use that existing CA Secret with `selfSignedCertificate.enabled=true`, `selfSignedCertificate.secret.useExistingSecret=true`, `selfSignedCertificate.secret.name=argocd-server-ca`, and `selfSignedCertificate.secret.key=crt`; do not disable TLS verification.

Install with `helm upgrade --install port-argocd-integration port-labs/port-ocean --version 0.20.2`, namespace `port-argocd-integration`, `secret.create=false`, `secret.name=port-argocd-integration-credentials`, and the tested non-secret values. Wait for rollout readiness.

- [ ] **Step 4: Verify chart rendering without secrets**

Run a `helm template` command using a temporary fake existing-secret name and assert the resulting Deployment references the existing secret. Run `bash tests/test_install_port_argocd_ocean.sh` and `bash -n scripts/install-port-argocd-ocean.sh`.

Expected: all commands exit zero without credential output.

### Task 4: Preflight, live deployment, and evidence

**Files:**
- Modify: `agentlog/argocd.md`
- Modify: `implementation-checklist.md`

- [ ] **Step 1: Check duplicate-integration risk**

Use the Port UI Data Sources page to confirm no existing installation uses identifier `argocd-portio1`. Record only the outcome, not credentials. Use the UI because Port MCP `list_integrations` currently fails on an unrelated response-schema mismatch.

- [ ] **Step 2: Apply the user configuration and deploy Ocean**

Run:

```bash
bash scripts/configure-port-argocd-ocean-user.sh
bash scripts/install-port-argocd-ocean.sh
kubectl --context kind-portio1 get pods -n port-argocd-integration
```

Expected: the Ocean Deployment is Ready.

- [ ] **Step 3: Verify integration behavior**

Inspect bounded recent logs without printing credentials:

```bash
kubectl --context kind-portio1 -n port-argocd-integration logs \
  deployment/port-argocd-integration --tail=200
```

Confirm successful startup and Argo CD synchronization, then use Port UI or authenticated Port MCP entity queries to verify Argo CD applications, projects, clusters, namespaces, and deployment history appear or refresh.

- [ ] **Step 4: Record evidence and commit**

Record chart version, installation identifier, namespace, resource readiness, sync outcome, and any manual Port UI step in `agentlog/argocd.md`. Mark only verified checklist items complete. Run all Ocean, chart, and Argo CD tests, inspect `git status` and `git diff`, then commit the secret-free files.
