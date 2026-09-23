# InnerLamp Knowledge Bundle

This directory is an [OKF](../Specs/OKF.md) (Open Knowledge Format)
bundle: structured, cross-linked markdown documents describing InnerLamp
features, APIs, and architecture for both humans and AI agents to
reference. See `Docs/Specs/OKF.md` for the full rationale, naming
decision, and adoption plan.

Unlike `Docs/Specs/<feature>/` (mutable, written *before*/*during* work —
requirements/design/tasks), concepts here are generated *after* a feature
is verified working, and are meant to stay accurate as a durable
reference. See `Docs/Specs/OKF.md` §3 for the full workflow.

## Sections

- [`features/`](features/) — one concept per user-facing feature
  (`type: Feature`), each pointing at its real code location via
  `resource:`.

Planned, not yet populated:

- `api/` — API endpoint concepts (`type: API Endpoint`). The SignUp
  `request-otp` endpoint is implemented and has a confirmed contract, but
  its concept is not written yet; add it alongside the other auth
  endpoints.
- `domain/` — Domain Entity / UseCase concepts for cross-feature business
  rules.
- `architecture/` — stable architecture patterns (Coordinator, DI,
  transitions, logging groups); written once, rarely updated.
- `design-system/` — Design token / component concepts mirroring
  `Presentation/Common/DesignSystem/Tokens/DESIGN_SYSTEM.md`.

## Concepts in this bundle

| Concept | Type | Status |
|---|---|---|
| [features/signup.md](features/signup.md) | Feature | draft (real-backend verification pending; ordination-place copy unconfirmed; ToS/Privacy links unwired) |
| [features/login.md](features/login.md) | Feature | draft (backend integration pending) |

See `log.md` for the change history of this bundle.
