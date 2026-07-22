# Phase 5 Port Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expose a service-scoped Port action that provisions a development environment through GitHub, Argo CD, and Kubernetes.

**Architecture:** Reuse canonical `service`, `environment`, `workload`, `argocdApplication`, and Kubernetes blueprints. Labels on deployed workloads drive deterministic relations; no parallel demo catalog model is introduced.

**Tech Stack:** Port MCP, GitHub Ocean, Kubernetes exporter, Argo CD integration.

---

### Task 1: Diff and extend catalog additively

**Files:**
- Create: `port/blueprints/development-environment.json`
- Create: `port/mappings/kubernetes-workload-mapping.yaml`
- Test: Port MCP read queries

- [ ] Retrieve current blueprint schemas and exporter mapping before any update.
- [ ] Add a `dev_environment` blueprint only if a persistent request entity is required; otherwise retain service-scoped action runs only.
- [ ] Extend Kubernetes workload mapping to use explicit `portWorkload`, `portService`, and `portEnvironment` labels.
- [ ] Test the complete revised mapping against exporter examples before applying it.
- [ ] Apply only after all expected relations resolve to real entities.

### Task 2: Connect GitHub and create action

**Files:**
- Create: `port/actions/provision-development-environment.json`
- Modify: `implementation-checklist.md`

- [ ] Confirm GitHub integration installation ID and workflow dispatch capability; stop for UI reauthorization if MCP cannot retrieve it.
- [ ] Define a DAY-2 `Provision Development Environment` action on `service` with environment name, size, owner, and expiration inputs.
- [ ] Dispatch the Phase 4 workflow and enable status reporting when supported.
- [ ] Trigger against a real test service and verify the Port run receives a terminal status and GitHub link.

### Task 3: Verify end-to-end catalog graph

**Files:**
- Modify: `agentlog/port-configuration.md`

- [ ] Verify Git commit, Argo CD Application, namespace, Kubernetes workload, and canonical service relations.
- [ ] Record unsupported MCP/UI steps and all applied identifiers.
