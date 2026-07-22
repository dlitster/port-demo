# Argo CD Ocean Integration Design

## Goal

Deploy Port's Argo CD Ocean integration into `kind-portio1` so Argo CD resources are periodically ingested into the EU Port organization.

## Architecture

The repository will store declarative, partial ConfigMap manifests for the dedicated `port-ocean-user` and its read-only Argo CD RBAC policy. They will be server-side applied to preserve unrelated Argo CD configuration.

An ignored root `.env` supplies `PORT_CLIENT_ID`, `PORT_CLIENT_SECRET`, `PORT_BASE_URL=https://api.port.io`, and an `ARGOCD_TOKEN` generated manually for the dedicated account. A local installer creates a Kubernetes Secret from those values and installs pinned `port-labs/port-ocean` chart `0.20.2` into `port-argocd-integration` with `secret.useExistingSecret=true`; credentials never enter Git, Helm values files, or command-line `--set` arguments.

Ocean connects to `https://argocd-server.argocd.svc.cluster.local`, uses integration identifier `argocd-portio1`, polls every 120 minutes, and initializes the native Argo CD Port resources.

## Safety Boundaries

- `port-ocean-user` has API-token and login capabilities only.
- Its Argo CD RBAC policy permits only `get` access to applications, clusters, projects, and repositories.
- Ocean receives no Kubernetes RBAC configuration from this work.
- The installer must refuse a missing, blank, or invalid local credential set before mutating the cluster.
- Existing Port Argo CD integration identifiers must be checked in the Port UI before deployment because the MCP integration-list response has a known schema error.

## Validation

Tests will inspect the manifests and installer for the account, policy, pinned Ocean version, EU API URL, in-cluster Argo CD URL, polling interval, secret references, and no plaintext credentials. Live verification will confirm the Ocean workload is Ready, emits successful authentication/sync logs, and ingests or refreshes `argocdApplication`, `argocdProject`, `argocdCluster`, `argocdNamespace`, and `argocdDeploymentHistory` entities.
