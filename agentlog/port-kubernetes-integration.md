# Port Kubernetes Integration Workstream

## Scope

Install and verify Port's Kubernetes exporter for `portio1`.

## Log

- 2026-07-22: Confirmed Port has no Kubernetes exporter integration installed.
- 2026-07-22: Exporter requires local Port client ID and client secret; values will remain only in ignored `.env`.
- 2026-07-22: Added a credential-guarded installer that creates a Kubernetes Secret from `.env` and configures chart version `0.3.28` to reference that Secret.
- 2026-07-22: Installer correctly stops before creating cluster resources while credentials are empty.
- 2026-07-22: Verified `port-labs/port-k8s-exporter` chart version `0.3.28` is available from the official Helm repository.
- 2026-07-22: Installed exporter release `port-k8s-exporter` into namespace `port-k8s-exporter`; deployment is Ready.
- 2026-07-22: Port ingestion confirmed `k8s_cluster/portio1` and `k8s_node/portio1-control-plane-portio1`.
- 2026-07-22: Namespace, workload, ReplicaSet, and pod entities are pending due to initial relation-order failures. Deferred by user.
- 2026-07-22: User-triggered resync completed without failed upserts and resolved initial relation-order failures.
- 2026-07-22: Verified Port entities: 1 cluster, 1 node, 3 namespaces, 2 workloads, 4 ReplicaSets, and 2 pods.
