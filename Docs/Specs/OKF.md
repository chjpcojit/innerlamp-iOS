# OKF (Open Knowledge Format) — Discussion Summary & Adoption Plan

> Status: Adopted. The bundle lives at `Docs/Knowledge/`, and the
> convention is automated by the `okf-writer` skill
> (`.claude/skills/okf-writer/`). Sections 1–3 record the original
> discussion and remain accurate; sections 4–6 are updated below to
> reflect what was actually built.

---

## 1. What is OKF?

OKF (Open Knowledge Format) originates from Google's
[`GoogleCloudPlatform/knowledge-catalog`](https://github.com/GoogleCloudPlatform/knowledge-catalog)
repository (now maintained separately at
[`GoogleCloudPlatform/open-knowledge-format`](https://github.com/GoogleCloudPlatform/open-knowledge-format)).

It is **not a library, SDK, or tool to install** — it is a **vendor-neutral
convention** for representing knowledge as plain markdown files with YAML
frontmatter, organized in a directory hierarchy ("bundle"). Key properties:

- **Human- and agent-readable**: no SDK or query language required; an
  engineer can `cat` a file, an LLM can ingest it directly into context.
- **Version-controllable**: bundles live in git, so diffs, blame, and PR
  review work naturally.
- **Structured + unstructured mix**: YAML frontmatter holds queryable
  fields (`type`, `resource`, `tags`, `generated`, `status`); the markdown
  body holds prose, schemas, and examples for humans/LLMs to read.
- **Provenance, trust, and freshness as first-class fields** (v0.2):
  `sources` (where a concept came from), `generated`/`verified` (who
  produced/confirmed it — used to derive a trust tier), `status` /
  `stale_after` (whether it is still current).
- **Graph-shaped**: concepts link to each other via normal markdown links,
  not just parent/child directory nesting.

The original repo also ships a reference agent (BigQuery + web crawling)
and an HTML graph visualizer as a **proof of concept** for producing and
consuming OKF bundles — those specific tools are not relevant to
InnerLamp (iOS, no BigQuery), but the **format itself** is directly
useful as a lightweight context layer for AI coding agents.

---

## 2. Why it matters for InnerLamp

InnerLamp already relies on structured documentation for AI agents
(`AGENTS.md`, per-module `README.md` files under `Core/Base/` and
`Core/Logging/`, `DESIGN_SYSTEM.md`). OKF formalizes this same idea with
a few useful additions:

- One concept = one file, cross-linked, instead of one large monolithic
  doc. This enables **progressive disclosure**: an agent reads only the
  concept(s) it needs instead of the whole codebase or a huge README.
- `resource:` frontmatter field ties a knowledge document directly to a
  real file/path in the codebase (e.g. `Presentation/Scenes/SignUp/`),
  making it traceable and diffable against actual code drift.
- `generated` / `verified` fields distinguish AI-authored documentation
  from human-reviewed documentation — important since AI agents (like
  Copilot CLI) may auto-generate these docs after implementing a feature.

---

## 3. Workflow: when and how OKF gets updated

**Key conclusion from the discussion: OKF documents are not a spec written
before implementation — they are generated *after* a feature is built, and
serve as a reference/verification artifact, not a work order.**

```
User gives a direct instruction (e.g. "build Signup feature")
   → AI implements the feature (Coordinator/ViewModel/ViewController/
     UseCase/Repository/DTO, DI registration, unit tests — per AGENTS.md §5)
   → Build + tests pass, feature confirmed working
   → AI generates/updates the corresponding OKF concept(s)
     (tagged generated: { by: copilot-cli, at: <timestamp> })
   → Human reviews the PR (code + OKF concept together)
   → If correct, human adds verified: { by: human:<name>, at: <timestamp> }
   → The concept becomes a trusted reference for future work on that
     feature (regression, extension, onboarding a new agent context)
```

Exception: for complex business rules that benefit from being written down
*before* coding (e.g. a multi-step OTP flow), a concept may be drafted
first without a `resource:` field (since no code exists yet), acting as a
lightweight spec. Once implemented, the same concept is updated to add
`resource:` and reconciled with the final implementation.

**Practical rule of thumb: implement → verify it works → update OKF in the
same PR.** Documentation written long after the fact tends to go stale.

---

## 4. Naming decision

Considered names: `okf/`, `knowledge/`, `kb/`, `context/`, `il-knowledge/`,
`atlas/`.

**Decision: use `Knowledge/`** as the folder name instead of `okf/`.

**Actual location (as built): `Docs/Knowledge/`** — nested inside the
existing `Docs/` folder, not at repo root. The original plan put it at
repo root "alongside `Docs/`"; in practice nesting it under `Docs/` keeps
all non-source documentation under one parent, which is what shipped.

Reasoning:
- Self-descriptive — no explanation needed for a newcomer browsing the repo.
- Inside `Docs/`, the capital-K `Knowledge/` name sets the bundle apart
  from its sibling folders, which hold human-facing design/handoff
  material (Figma exports, launch images): `Docs/Knowledge/` holds
  structured, AI-referenceable knowledge about features, APIs, and
  architecture.
- Avoids implying InnerLamp depends on Google's actual OKF tooling/repo —
  InnerLamp only borrows the **markdown + frontmatter convention**, not
  any code or service from `open-knowledge-format`.

> ⚠️ Note on casing: the original plan in this document said `knowledge/`
> (lowercase, repo root); what shipped is `Docs/Knowledge/` (capital K,
> nested under `Docs/`). Any path referencing the bundle must use the
> capital-K spelling — on macOS a lowercase `knowledge/` resolves to the
> same directory, so a wrong-cased path will silently work locally and
> break on a case-sensitive CI checkout.

---

## 5. Folder structure (as built)

```
Docs/Knowledge/                    # Bundle root — nested under Docs/
  index.md                         # Bundle-wide table of contents
  log.md                           # Chronological changelog of concept updates

  features/                        # type: Feature
    signup.md                      # resource: InnerLamp/Presentation/Scenes/SignUp/
    login.md                       # resource: InnerLamp/Presentation/Scenes/Login/
    forgot-password.md             # (not yet written)
    otp.md                         # (not yet written)
    onboarding.md                  # (not yet written)
    home.md                        # (not yet written)
    splash.md                      # (not yet written)

  api/                             # type: API Endpoint
    auth-signup.md                 # real request/response, linked to Core/Networking Endpoint
    auth-login.md
    auth-otp-verify.md

  domain/
    entities/                      # type: Domain Entity
      user.md                      # resource: InnerLamp/Domain/Entities/ILUserEntity.swift
    usecases/                      # type: UseCase
      signup-usecase.md            # resource: InnerLamp/Domain/UseCases/SignUp/

  architecture/                    # type: Architecture Pattern (written once, rarely updated)
    coordinator-pattern.md
    base-viewmodel-flow.md
    di-container.md
    transition-system.md
    logging-groups.md

  design-system/                   # type: Design Token / Component
    tokens/
      il-colors.md
      il-typography.md
      il-metrics.md
    components/
      il-button.md
      il-field.md
      ...                         # mirrors the DesignSystem components under
                                  # InnerLamp/Presentation/Common/DesignSystem/Components/
```

### Update frequency by category

| Folder | Type | Update frequency | Trigger |
|---|---|---|---|
| `features/` | Feature | High | After each new/changed feature ships |
| `api/` | API Endpoint | High | After each new/changed endpoint |
| `domain/entities`, `domain/usecases` | Domain Entity, UseCase | Medium | When an entity or business rule changes |
| `architecture/` | Architecture Pattern | Low | Only when a foundational pattern changes |
| `design-system/` | Design Token, Component | Low–Medium | When a new token/component is added to `DESIGN_SYSTEM.md` |

---

## 6. Automation

The convention is automated by the **`okf-writer`** skill
(`.claude/skills/okf-writer/`), which enforces:

- **Post-implementation only** — a concept is written after the code is
  implemented and verified, never as a work order. Writing a design
  *before* code is `spec-writer`'s job, under `Docs/Specs/<Feature>/`.
- **`resource:` paths are verified against the filesystem**, never guessed.
  A concept with no code yet omits `resource:` instead of inventing a path.
- **`status: draft` stays until the flow is exercised end-to-end.** A
  stubbed call keeps the whole concept at `draft`.
- **`verified:` is never written by the AI** — only a human adds it during
  PR review. The AI writes `generated:` alone.
- **Every create/update also refreshes `index.md` and `log.md`** — no
  orphan concepts, no silent edits.

### Remaining work

- [ ] Backfill the unwritten `features/` concepts (OTP, Onboarding,
      Forgot Password, Home, Splash) and the `api/` concepts once real
      backend contracts exist.
- [ ] Add a step to AGENTS.md §5 ("Process for AI Creating a New Feature")
      instructing the AI to invoke `okf-writer` after a feature is
      implemented and verified.
- [ ] Decide whether `Docs/Knowledge/` concepts are reviewed as part of the
      normal PR review process (recommended) or on a separate cadence.
