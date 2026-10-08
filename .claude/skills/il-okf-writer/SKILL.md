---
name: il-okf-writer
description: This skill should be used when the user wants to create or update a knowledge concept in the InnerLamp OKF (Open Knowledge Format) bundle under Docs/Knowledge/ — a post-implementation reference document describing a feature, API endpoint, domain entity, UseCase, architecture pattern, or design-system token/component, with YAML frontmatter (type, title, resource, tags, status, generated, sources, verified), a resource: path pointing at the real code location, and cross-links to related concepts. It enforces that concepts are generated only AFTER the code is implemented and verified (never as a work order — that is il-spec-writer's job under Docs/Specs/), that every resource: path is checked against the filesystem rather than guessed, that status stays draft until the flow is exercised end-to-end, that the verified: field is never written by the AI (only a human adds it during PR review), and that every create/update also refreshes index.md and log.md. It never writes Swift code and never touches Docs/Specs/. Replaces the dangling "Docs/Knowledge/features/<feature>.md (OKF concept)" task item left open in il-spec-writer's Phase 4 template.
model: claude-sonnet-5-5
---

# InnerLamp OKF Writer

## Overview

Generates and maintains concepts in the InnerLamp OKF bundle at `Docs/Knowledge/` — the
post-implementation, durable knowledge layer described in `Docs/Specs/OKF.md`.

A **concept** is one markdown file with YAML frontmatter, covering exactly one thing: one feature,
one API endpoint, one entity, one UseCase, one architecture pattern, one design token group, or one
component. Concepts cross-link to each other; they are not a single monolithic document.

Read these first, in this order, before generating anything:

1. `Docs/Specs/OKF.md` — the format rationale and the workflow rules this skill implements.
2. `Docs/Knowledge/index.md` — the bundle's table of contents (current sections + concept table).
3. `Docs/Knowledge/features/signup.md` and `features/login.md` — the canonical worked examples.
   Copy their tone, section ordering, and frontmatter shape.

**This skill is post-implementation only.** A concept documents code that exists and works. It is
not a spec and must never be used as a work order — writing specs before/during implementation is
`il-spec-writer`'s job under `Docs/Specs/<Feature>/`. The one documented exception is a complex
business rule (e.g. a multi-step OTP flow) drafted as a concept *before* coding without a
`resource:` field; once implemented, that same concept gains `resource:` and is reconciled against
the real code (see `Docs/Specs/OKF.md` §3).

## Hard rules that override everything else below

1. **Never write a `resource:` path without verifying it exists on disk.** Run `ls`/`Glob` against
   the path before writing the frontmatter. A guessed or stale path silently breaks the concept's
   only link to reality. See `references/resource_verification.md`.
2. **Never write the `verified:` field.** It is a human attestation added during PR review by the
   person who confirmed the concept matches the code. An AI-authored `verified` destroys the
   trust-tier distinction the format exists to provide. Only omit, or preserve an existing value
   untouched — never create or change one.
3. **`status:` is `draft` until the described behavior is exercised end-to-end** against a
   real/staging backend. A feature whose API call is still a `print("TODO")` stub is `draft` no
   matter how complete its UI is — and the concept must say so plainly in a "Pending work" section,
   never folded into present-tense claims of working behavior.
4. **`generated.by` must name the agent actually authoring it.** Use `claude-code` when this skill
   writes the concept. Never copy `copilot-cli` forward from an existing file into a file this
   skill authored.
5. **Every create and every update also updates `index.md` and `log.md` in the same pass.** A
   concept that is not listed in `index.md` is effectively invisible; a change with no `log.md`
   entry has no history. See `references/bundle_management.md`.
6. **Read the code, do not trust the concept or README.** When updating an existing concept,
   re-read the source files it points at. Documentation drift — a concept describing a method that
   was renamed, a layer that was deleted — is the specific failure this bundle exists to prevent.
   See `references/resource_verification.md`.
7. **Never invent a claim to fill a section.** If a section does not apply (a feature with no
   validation rules, an endpoint with no auth), omit the section. Do not write placeholder prose
   and do not guess an unconfirmed backend contract — mark it pending instead, exactly as the
   SignUp/Login concepts do.

## Reference map

Load only what the task needs; do not read all of these upfront.

| Reference | Covers |
|---|---|
| `references/frontmatter_schema.md` | Every frontmatter field, its type, allowed values, and the `verified`/`stale_after` trust-tier rules |
| `references/concept_types.md` | The seven `type:` values, which bundle section each lives in, and how to pick the right one |
| `references/bundle_management.md` | `index.md` concept-table row format, `log.md` entry format and reverse-chronological ordering, naming and cross-link rules |
| `references/resource_verification.md` | How to verify a `resource:` path, what to do when the target is a folder vs a file vs missing, and how to detect drift against an existing concept |
| `references/gathering_questions.md` | The question set to ask before generating, and when a question can be skipped |

## Workflow

### 1. Determine intent and gather required decisions

Establish, asking the user only for what cannot be determined from the code and the bundle:

1. **What is being documented** — a feature, endpoint, entity, UseCase, architecture pattern, or
   design-system token/component. This picks the `type:` and the section folder (see
   `references/concept_types.md`).
2. **Create or update?** Check whether the target file already exists under `Docs/Knowledge/`. An
   existing file means update — go to step 4.
3. **Is the thing actually implemented?** If it is not built yet, stop: this is spec work for
   `il-spec-writer`, not OKF work. The only exception is the complex-business-rule draft described
   in the Overview.

See `references/gathering_questions.md` for exact phrasing. Ask no more than necessary — most
answers are discoverable by reading the code and the existing bundle.

### 2. Read the source of truth

Before writing a single line, read the real code the concept will describe:

| Concept type | Read |
|---|---|
| Feature | `InnerLamp/Presentation/Scenes/<Feature>/` (every file, including `Views/`), `InnerLamp/Domain/Entities/`, `InnerLamp/Domain/UseCases/<Feature>/`, and the feature's `README.md` if present |
| API Endpoint | `InnerLamp/Core/Networking/Endpoint.swift`, the feature's `Endpoint` conformance, its DTO and Mapper |
| Domain Entity | the entity file itself, plus every UseCase that constructs or consumes it |
| UseCase | the protocol and its `Impl`, plus the ViewModel that calls it |
| Architecture Pattern | `InnerLamp/Core/Base/README.md`, the relevant `Core/` source files, and two or three features that follow the pattern |
| Design Token / Component | `InnerLamp/Presentation/Common/DesignSystem/Tokens/DESIGN_SYSTEM.md`, the component's `.swift` file, and two or three call sites |

Then verify the `resource:` path per `references/resource_verification.md` — actually check it,
do not assume it from the folder listing you used to find the code.

Note what is stubbed, unwired, or known-broken while reading. Those become the concept's "Pending
work" and "Known gaps vs. design" sections, and they are usually the most valuable content in the
file — they are what a future reader (or agent) cannot rediscover cheaply.

### 3. Create the concept

Copy the matching template from `assets/templates/`, replace the `{{...}}` placeholders, and fill
in real content:

| Type | Template | Destination |
|---|---|---|
| Feature | `assets/templates/feature.md.template` | `Docs/Knowledge/features/<feature-lower>.md` |
| API Endpoint | `assets/templates/api-endpoint.md.template` | `Docs/Knowledge/api/<domain>-<action>.md` |
| Domain Entity | `assets/templates/domain-entity.md.template` | `Docs/Knowledge/domain/entities/<entity-lower>.md` |
| UseCase | `assets/templates/usecase.md.template` | `Docs/Knowledge/domain/usecases/<usecase-lower>.md` |
| Architecture Pattern | `assets/templates/architecture-pattern.md.template` | `Docs/Knowledge/architecture/<pattern-lower>.md` |
| Design Token group | `assets/templates/design-token.md.template` | `Docs/Knowledge/design-system/tokens/<token-group-lower>.md` |
| Component | `assets/templates/design-component.md.template` | `Docs/Knowledge/design-system/components/<component-lower>.md` |

Sections the templates require for every type: `# Summary` (present tense, what it is and where it
sits), `# Architecture` (a layer/type/file table naming real files), and `# Related concepts`
(relative markdown links to sibling concepts — link liberally, and a link to a concept that does
not exist yet is acceptable and useful as a marker).

Then create any section folder the concept needs that does not exist yet, and register the concept
per step 5.

### 4. Update an existing concept

When the target file already exists:

1. Read the current concept, then re-read every file listed in its Architecture table and its
   `resource:` target. Note every discrepancy — renamed symbol, moved file, changed validation
   rule, a stub that has since been implemented.
2. Rewrite the affected sections from the code, not from the old prose.
3. Re-evaluate `status:`: a stub that is now a real network call may promote the concept from
   `draft` to `stable` **only** if the flow has been exercised end-to-end. If unsure, leave it
   `draft` and say what is still unverified — do not promote on the strength of the code merely
   existing.
4. Update `generated.at` to the current timestamp.
5. Preserve `verified:` untouched if present. If the concept changed materially and a `verified:`
   field exists, note in your response to the user that the human verification is now stale and
   should be re-confirmed in review — but do not remove the field yourself.
6. Update `index.md` if the concept's row description or status changed, and add a `log.md` entry
   describing what changed and why.

### 5. Refresh index.md and log.md

Every create/update ends here — this is not optional (rule 5):

- Add or update the concept's row in `Docs/Knowledge/index.md`'s concept table, and move it out of
  any "Planned, not yet populated" list once its section has its first concept.
- Add an entry to `Docs/Knowledge/log.md`, newest first, describing what was reviewed for
  accuracy, what the concept documents, what remains pending, and why `status` is what it is.

Formats for both: `references/bundle_management.md`.

### 6. Verify before reporting done

- The `resource:` path exists on disk and points at the entity the concept actually describes.
- Every file named in the Architecture table exists at the path written.
- `generated.by` names this agent, and `generated.at` is current.
- No `verified:` field was authored or altered.
- `status:` matches reality — `draft` if anything described is stubbed, unwired, or unverified
  end-to-end, with a "Pending work" section listing exactly what.
- Every `# Related concepts` link uses a correct relative path from the new file's location.
- `index.md` and `log.md` both reflect this concept, and every `[[...]]`-style or markdown link
  target you claim exists actually exists.
- Nothing under `Docs/Specs/` was modified, and no Swift file was touched.
