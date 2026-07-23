# Implementation Checklist

## Phase 1: Cluster And Port Baseline

- [x] Agree on a dedicated kind cluster name: `portio1`.
- [x] Create workstream logs and this checklist.
- [x] Create the `portio1` kind cluster.
- [x] Verify the `kind-portio1` context and Ready control-plane node.
- [x] Resolve the `kube-proxy` inotify-instance limit blocker before installing workloads.
- [x] Obtain Port client credentials locally and seed `.env`.
- [x] Install the Port Kubernetes exporter with `CLUSTER_NAME=portio1`.
- [x] Verify the exporter deployment is Ready.
- [x] Verify `portio1` appears as a Kubernetes cluster entity in Port.
- [x] Verify the exporter namespace appears in Port.
- [x] Verify the control-plane node appears in Port.

## Later Phases

### Phase 2: Helm Development-Environment Chart

- [x] Define and validate chart values for owner, service, expiration, profile, image, optional HTTP Service, and optional Port run ID.
- [x] Enforce fixed small, medium, and large resource profiles that cannot be overridden through Helm values.
- [x] Render Namespace, ResourceQuota, LimitRange, RoleBinding, Deployment, and optional Service resources.
- [x] Use stable Deployment and Service selectors without profile or expiration labels.
- [x] Verify strict Helm lint, invalid-value rejection, Kubernetes server-side validation, live deployment readiness, and uninstall cleanup.

### Phase 3: Argo CD Project And ApplicationSet

- [x] Configure and push the initial `master` branch to `https://github.com/dlitster/port-demo`.
- [x] Install pinned Argo CD `v3.4.5` in `argocd` on `kind-portio1` with server-side apply.
- [x] Verify Argo CD server, repo server, application controller, and ApplicationSet controller are ready.
- [x] Create a constrained AppProject for the repository, in-cluster destination, `dev-*` namespaces, and allowed resource kinds.
- [x] Apply a Git-directory ApplicationSet for `environments/*/*` with automated sync, pruning, self-healing, and namespace creation.
- [x] Verify `dev-checkout-api` is `Synced` and `Healthy` with its expected Kubernetes resources.

### Phase 3.1: Port Argo CD Ocean Integration

- [x] Document the design and implementation plan for the dedicated Argo CD read-only Ocean user and integration.
- [x] Confirm `argocd-portio1` is not already registered as a Port integration.
- [x] Add server-side-applied Argo CD account and RBAC manifests for `port-ocean-user`.
- [x] Generate the dedicated Argo CD API token locally and store it only in ignored `.env`.
- [x] Install pinned Port Ocean `0.20.2` with an existing Kubernetes Secret in `port-argocd-integration`.
- [x] Verify Ocean authentication and successful HTTPS Argo CD API synchronization.
- [ ] Verify refreshed Port Argo CD entities after the Ocean resync.
- [ ] Record deployment evidence in `agentlog/argocd.md`.

### Phase 4: GitHub Provisioning Workflow

- [x] Build and test the environment-values writer with input validation, deterministic YAML, duplicate rejection, and symlink protection.
- [x] Persist the optional Port run ID as a safe workload annotation.
- [x] Create and test the GitHub Actions workflow for manual and repository-dispatch provisioning requests.
- [x] Configure workflow checkout, per-environment concurrency, commit, push, outputs, and job summary.
- [x] Dispatch a unique test environment and verify Argo CD deploys it.
- [x] Dispatch the same inputs again and verify duplicate rejection.
- [x] Record the workflow URL, commit SHA, and duplicate-rejection evidence in `agentlog/github-workflow.md`.

### Phase 5: Port Action, Integrations, And Catalog Relationships

- [x] Inspect existing Port blueprints, Kubernetes exporter mapping, and GitHub integration capabilities.
- [x] Extend catalog mappings only as needed for workload, service, environment, and Argo CD relations.
- [x] Test revised mappings against integration examples before applying them.
- [x] Create a service-scoped Provision Development Environment action that dispatches the GitHub workflow.
- [x] Trigger the action for a real service and verify the Port run, Git commit, Argo CD Application, namespace, and catalog relations.
- [x] Record applied identifiers and any unsupported UI or MCP steps in `agentlog/port-configuration.md`.

### Phase 6: Demo Data, Scorecard, Dashboard, And Rehearsal

- [ ] Seed six realistic services with varied ownership and operational metadata.
- [ ] Create development-environment compliance rules with deliberately mixed outcomes.
- [ ] Verify scorecard level distribution includes passing and failing environments.
- [ ] Create a dashboard with service, environment, ownership, Argo health, compliance, and action metrics.
- [ ] Verify every dashboard widget has non-empty data and mixed results where intended.
- [ ] Write and rehearse an end-to-end demo script and cleanup procedure.

## Rules

- Keep secrets only in the ignored root `.env` file.
- Log commands and outcomes without recording credential values.
- Complete each phase's acceptance checks before starting the next phase.
- The host currently requires `fs.inotify.max_user_instances=1024` for a new kind cluster to start all components.
