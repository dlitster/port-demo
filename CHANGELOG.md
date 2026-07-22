# Changelog

All notable changes to this Port and Argo CD demo are documented here.

## Unreleased

### Added

- Phase 3.1 design and implementation plan for the Port Argo CD Ocean integration.
- Phase 4 environment-values writer with strict request validation, safe YAML serialization, duplicate refusal, and symlink-escape protection.
- Optional `platform.example.com/port-run-id` chart annotation to trace provisioning requests.
- Detailed implementation checklist entries for Phases 2 through 6.

### Changed

- Added purpose and phase headers to every repository shell script.

### Planned

- Deploy the Port Argo CD Ocean integration as Phase 3.1.
- Complete the Phase 4 GitHub Actions provisioning workflow.

## 2026-07-22

### Added

- Dedicated `kind-portio1` cluster creation, destruction, and Port Kubernetes exporter installation scripts.
- `development-environment` Helm chart with fixed resource profiles and optional HTTP Service.
- Argo CD v3.4.5 installer, constrained AppProject, and Git-directory ApplicationSet.
- Sample `dev-checkout-api` environment reconciled from `master` and verified `Synced Healthy`.
