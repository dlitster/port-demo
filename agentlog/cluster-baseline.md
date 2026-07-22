# Cluster Baseline Workstream

## Scope

Create and verify the dedicated `portio1` kind cluster.

## Log

- 2026-07-22: Phase 1 started. Existing `k8s-cicd` cluster was inspected only.
- 2026-07-22: Selected `portio1` as the isolated challenge cluster name.
- 2026-07-22: Created `portio1` with `kindest/node:v1.36.1`; the control-plane node is Ready.
- 2026-07-22: Blocked on `kube-proxy`, which exits while opening its config watcher with `too many open files`.
- 2026-07-22: Host `fs.inotify.max_user_instances` is 128. Raising this host-wide limit requires explicit approval.
- 2026-07-22: Raised `fs.inotify.max_user_instances` to 1024 and restarted only `kube-proxy`.
- 2026-07-22: Recovered CoreDNS and restarted the local-path provisioner after the earlier service-network outage.
- 2026-07-22: Verified one Ready node, all system pods Ready, and the default `standard` StorageClass.
