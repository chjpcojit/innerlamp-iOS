---
name: il-spec-writer
description: This skill should be used when the user wants a written spec (requirements, design, or task breakdown) for an InnerLamp iOS feature — before, during, or retroactively after building it — covering the three-file convention under Docs/Specs/<Feature>/ (requirements.md, design.md, tasks.md) plus a changelog.md, matching the existing Docs/Specs/SignUp/ example. It enforces a strict one-way cascade (requirements → design → tasks: a requirement change always updates design, which always updates tasks, never the reverse), EARS-notation acceptance criteria in requirements.md, a mandatory "Step-by-step Flow" section in design.md for any flow with 2+ sequential API/network calls (spelling out trigger/pre-condition/API/success-failure per step so hidden steps like a duplicate check or a secondary verification call are never silently assumed), version headers + changelog entries on every file for every update, and a hard rule that any unanswered question from the user is recorded inline as "⚠️ Not confirmed" — never skipped, never guessed, never silently defaulted. It is a docs-only skill: it never writes Swift code (that is `il-screen-builder`'s job) and never writes to Docs/Knowledge/ (the separate, post-implementation-only OKF convention described in Docs/Specs/OKF.md).
model: claude-sonnet-5-5
---

# InnerLamp Spec Writer

## Overview

Generates and maintains the three-file spec convention for an InnerLamp feature under
`Docs/Specs/<Feature>/`:

- `requirements.md` — **what** the system must do, from the user's perspective (user story +
  EARS-notation acceptance criteria).
- `design.md` — **how** it is built and how it operates (layers/components, navigation flow, and
  a step-by-step technical sequence for any multi-call flow).
- `tasks.md` — **what to actually do, in order**, broken down directly from `design.md`'s layers,
  organized into numbered Phases, each item a checkbox (`[ ]` pending / `[x]` done).
- `changelog.md` — one shared version history for all three files above (they change together as
  one spec unit).

This skill is modeled on the existing `Docs/Specs/SignUp/` files — read them first as the
canonical worked example before generating a new spec, especially to see the exact tone/format
expected (EARS phrasing, table shapes, ASCII flow diagrams).

**This skill never writes application code.** Turning a finished, fully-resolved spec into actual
Swift files (Entity/UseCase/ViewModel/Coordinator/ViewController/DI wiring) is `il-screen-builder`'s
job, not this one. This skill also never touches `Docs/Knowledge/` — that is the separate OKF
convention (see `Docs/Specs/OKF.md`), generated *after* code is implemented and verified, as a
trusted reference artifact, not a work-order spec.

## Hard rules that override everything else below

1. **One-way cascade, always in this order: `requirements.md` → `design.md` → `tasks.md`.** A
   requirement changes first; that change is then reflected in the relevant part of `design.md`;
   only then does `tasks.md` get new/updated checklist items. Never edit `tasks.md` based on a
   requirement change without first updating `design.md` to explain *how* that requirement will be
   met technically.
2. **Never mark a task `[x]` unless it is actually implemented in the codebase.** Newly-scoped or
   newly-changed work is always `[ ]`, even if the change itself (i.e. writing the spec) is done —
   writing the spec is not the same as implementing the feature.
3. **Any user question left unanswered is recorded, never skipped or guessed.** Use this exact
   inline format at the most specific relevant location (not just dumped at the top of the file):
   ```
   > ⚠️ Not confirmed: <the question, in one sentence> — <what it blocks / what depends on it>.
   ```
   When the user later answers it, move it to "Open questions (resolved)" in `requirements.md`
   with the resolution and date, and re-check whether that answer changes anything in `design.md`
   or `tasks.md` (it may simplify, expand, or leave them unchanged — record which).
4. **Every file update bumps `Version`/`Last updated` in that file's header and adds a
   corresponding entry to `changelog.md`.** No silent overwrites. See
   `references/versioning_and_changelog.md` for the exact bump rule and entry format.
5. **A "Step-by-step Flow" section in `design.md` is mandatory whenever a user flow involves 2 or
   more sequential API/network calls** (e.g. send-code → verify-otp → create-account), even if
   some of those calls belong to a different feature. See
   `references/step_by_step_flow.md` for why and how — this is the mechanism that prevents hidden
   steps (a duplicate-check call, a secondary verification step) from being silently assumed away
   in a one-sentence user story.
6. **Questions asked to the user must be short, concrete, and easy to answer** — one topic per
   question, with an example or a suggested default where possible. See
   `references/gathering_questions.md` for the required question set and phrasing style.

## Reference map

Read these as needed — don't load all upfront if the task is narrow.

| Reference | Covers |
|---|---|
| `references/modes.md` | The two operating modes — **Prospective** (spec written before code exists) vs **Retroactive** (spec written from an already-implemented feature) — and how each changes the generation process |
| `references/gathering_questions.md` | The exact question set to ask before generating anything, phrasing rules, and the "never skip, mark ⚠️" rule for unanswered ones |
| `references/ears_notation.md` | How to phrase `requirements.md` acceptance criteria in EARS notation, with good/bad examples |
| `references/step_by_step_flow.md` | When and how to write the `design.md` Step-by-step Flow section; the per-step fields required (trigger/pre-condition/API/success/failure) |
| `references/versioning_and_changelog.md` | Version bump rule (patch vs minor), required header format, and the `changelog.md` entry format with a worked multi-version example |

## Workflow

### 1. Determine mode and gather required decisions

Ask the user (see `references/gathering_questions.md` for exact phrasing) — do not proceed to
generation until each question has either an answer or an explicit "skip, mark unconfirmed":

1. **Feature name** (PascalCase, e.g. `Settings`, `PaymentHistory`) — the `<Feature>` folder name
   under `Docs/Specs/`.
2. **Mode**: Prospective (no code yet) or Retroactive (feature already implemented)? See
   `references/modes.md` — this materially changes step 2 below.
3. **One-sentence user story**: who is the user, what do they want, why.
4. **Cross-section navigation?** Does this screen get reached from outside its own feature flow
   (→ likely owned by `AppCoordinator`) or only from within one existing section?
5. **Does the main flow involve more than one sequential API/network call** (e.g. this feature's
   own call plus a follow-on call owned by another feature, like SignUp → OTP)? If yes, the
   Step-by-step Flow section (rule 5 above) is mandatory.
6. **Confirmed backend contracts?** For each API call identified in step 5, is the exact contract
   (endpoint, request/response shape, error cases) already confirmed, or still unknown? Unknown
   ones become `⚠️ Not confirmed` items, not assumed shapes.

### 2. Populate the three files + changelog

Copy each file in `assets/templates/` to `Docs/Specs/<Feature>/`, replacing `{{Feature}}` with the
PascalCase name, then fill in real content:

| Template | Destination | Key sections to fill |
|---|---|---|
| `assets/templates/requirements.md.template` | `Docs/Specs/<Feature>/requirements.md` | User Story, EARS Acceptance Criteria (`references/ears_notation.md`), Out of scope, Pending, Open questions |
| `assets/templates/design.md.template` | `Docs/Specs/<Feature>/design.md` | Overview, Layers & components table, Navigation flow, Step-by-step Flow (if rule 5 applies), Deliberately-stubbed-for-now section for any unconfirmed API |
| `assets/templates/tasks.md.template` | `Docs/Specs/<Feature>/tasks.md` | Phases broken down 1:1 from `design.md`'s Layers & components table — never invent a task that doesn't trace back to something named in `design.md` |
| `assets/templates/changelog.md.template` | `Docs/Specs/<Feature>/changelog.md` | Single `v1.0 (initial)` entry describing what this first version covers |

**Retroactive mode**: before filling `requirements.md`/`design.md`, read the actual feature code
(`InnerLamp/Presentation/Scenes/<Feature>/`, `InnerLamp/Domain/...`) so `tasks.md` accurately marks
what's `[x]` done vs `[ ]` pending — never assume a layer exists or is complete without checking.

**Prospective mode**: every task in `tasks.md` starts `[ ]`; `design.md` describes the intended
architecture, clearly distinguishing "will call a real API" vs "stubbed until a contract exists"
per the confirmed-backend-contracts answer from step 1.6.

### 3. Handle an existing spec being updated (not created fresh)

If `Docs/Specs/<Feature>/` already exists, this is an **update**, not a fresh generation:

1. Identify which file the change originates in. A new/changed user-facing behavior starts in
   `requirements.md`. A newly-discovered technical detail (e.g. confirming an API shape) may
   resolve directly in `design.md`/`requirements.md` without necessarily changing behavior.
2. Cascade per rule 1 above: `requirements.md` change → check/update `design.md` → check/update
   `tasks.md`. Explicitly state in your response (and in the changelog entry) if a downstream file
   did *not* need to change, and why — don't silently skip it without noting that you checked.
3. Bump version + add a changelog entry per `references/versioning_and_changelog.md`, describing
   what changed and why in plain language (not just "updated file").
4. If the change resolves a `⚠️ Not confirmed` item, move it to "Open questions (resolved)" in
   `requirements.md` with the resolution, and explicitly check (and state) whether it simplifies,
   expands, or leaves unchanged the affected part of `design.md`/`tasks.md`.

### 4. Verify before reporting done

- Every acceptance criterion in `requirements.md` is phrased in EARS notation (WHEN/THE SYSTEM
  SHALL), not vague prose.
- Every task in `tasks.md` traces back to a named layer/component in `design.md`'s table — no
  orphan tasks.
- No task is checked `[x]` unless it is genuinely implemented in the codebase (verify by reading
  the actual files if unsure, don't assume from the spec's own prior wording).
- Every `⚠️ Not confirmed` marker is either still open (and blocking the tasks that depend on it)
  or has been moved to "Open questions (resolved)" with a date and resolution.
- `Version`/`Last updated` headers match across all changed files, and `changelog.md` has one new
  entry per version bump, in reverse-chronological order (newest first).
- If the flow involves 2+ sequential API calls and no Step-by-step Flow section exists yet, add
  one before reporting done — this is not optional (rule 5).
