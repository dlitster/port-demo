# Argo CD Workstream

## Scope

Install and configure Argo CD, project policy, and ApplicationSet discovery.

## Log

- 2026-07-22: Installed Argo CD `v3.4.5` in `argocd` on `kind-portio1` with server-side apply. The installer waits for the server, repo server, application controller, and ApplicationSet controller.
- 2026-07-22: Applied the `development-environments` AppProject and ApplicationSet. The ApplicationSet reads public repository `https://github.com/dlitster/port-demo.git` without repository credentials.
- 2026-07-22: Verified generated Application `dev-checkout-api` is `Synced` and `Healthy`; it deployed to namespace `dev-checkout-api` with a Deployment, ClusterIP Service, ResourceQuota, LimitRange, and RoleBinding.
