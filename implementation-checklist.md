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

- [x] Phase 2: Helm development-environment chart.
- [x] Phase 3: Argo CD project and ApplicationSet.
- [ ] Phase 4: GitHub provisioning workflow.
- [ ] Phase 5: Port action, integrations, and catalog relationships.
- [ ] Phase 6: Demo data, scorecard, dashboard, and rehearsal.

## Rules

- Keep secrets only in the ignored root `.env` file.
- Log commands and outcomes without recording credential values.
- Complete each phase's acceptance checks before starting the next phase.
- The host currently requires `fs.inotify.max_user_instances=1024` for a new kind cluster to start all components.
