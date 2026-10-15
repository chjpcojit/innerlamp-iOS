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
- [`api/`](api/) — API endpoint concepts (`type: API Endpoint`), one per
  backend route, each linked to its `Endpoint` conformance and the
  feature(s) that call it.
- [`domain/`](domain/) — Domain Entity / UseCase concepts (`type: Domain
  Entity` / `type: UseCase`) for cross-feature business rules; `entities/`
  is not yet populated.
- [`architecture/`](architecture/) — stable architecture patterns
  (networking, logging groups); written once, rarely updated.

Planned, not yet populated:

- `domain/entities/` — shared domain-model concepts (e.g. `ILUserEntity`,
  `ILAuthSessionEntity`); currently documented within the feature/UseCase
  concepts that use them.
- `design-system/` — Design token / component concepts mirroring
  `Presentation/Common/DesignSystem/Tokens/DESIGN_SYSTEM.md`.

## Concepts in this bundle

| Concept | Type | Status |
|---|---|---|
| [features/home.md](features/home.md) | Feature | draft (mock data; no dashboard API) |
| [features/bell.md](features/bell.md) | Feature | draft (memory-only; no persistence or sound picker) |
| [features/library.md](features/library.md) | Feature | draft (mock catalog; search/item destinations TODO) |
| [features/main.md](features/main.md) | Feature | stable (complete container, no backend) |
| [features/temple.md](features/temple.md) | Feature | draft (mock catalog; SRS discovery scope unimplemented) |
| [domain/usecases/deviceattestation.md](domain/usecases/deviceattestation.md) | UseCase | draft (server round-trips stubbed until backend contract lands) |
| [architecture/networking.md](architecture/networking.md) | Architecture Pattern | stable (implemented + tested; 401 refresh deferred) |
| [architecture/logging-groups.md](architecture/logging-groups.md) | Architecture Pattern | stable (implemented; 3 of 4 transports mocked by design) |

See `log.md` for the change history of this bundle.
