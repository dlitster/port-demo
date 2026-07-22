# Phase 6 Demo Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce realistic catalog data, compliance scoring, dashboard views, and a repeatable demo rehearsal.

**Architecture:** Six varied services reuse the Phase 5 graph. A small readiness scorecard and dashboard intentionally show healthy and incomplete outcomes.

**Tech Stack:** Port blueprints/entities, scorecards, dashboards, Markdown demo runbook.

---

### Task 1: Seed realistic services

**Files:**
- Create: `port/entities/services.json`
- Test: Port entity count and relation queries

- [ ] Define six services: checkout-api, inventory-sync, pricing-engine, store-catalog, fulfillment-router, and returns-service.
- [ ] Assign varied teams, domains, tiers, lifecycle, runtime, repository, and deployment state.
- [ ] Upsert entities only after confirming the canonical service schema supports each field.
- [ ] Verify six entities and intended ownership diversity.

### Task 2: Add mixed environment compliance

**Files:**
- Create: `port/scorecards/development-environment-standards.json`
- Test: Port scorecard level distribution query

- [ ] Create rules for owner, service relation, approved profile, quota, expiration, and healthy Argo CD application.
- [ ] Seed only labeled demo environments with deliberate missing metadata or unhealthy state; never mask those conditions in comments.
- [ ] Verify both passing and failing scorecard levels exist.

### Task 3: Create dashboard and rehearsal

**Files:**
- Create: `docs/demo-script.md`
- Modify: `agentlog/demo-data.md`

- [ ] Create a dashboard with total services, total environments, compliant environments, missing ownership, Argo health, and action success rate.
- [ ] Verify every widget has non-empty data and mixed results.
- [ ] Write the ten-step end-to-end demo script and cleanup procedure.
- [ ] Rehearse the Port request through GitHub, Argo CD, Kubernetes, ingestion, scorecard, and dashboard.
