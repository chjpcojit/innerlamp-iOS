# Requirements — SutraDetail

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full detail screen with static catalog; no sutra API, and
the Download destination is not built (Reader/Player destinations are wired)
Feature folder: `InnerLamp/Presentation/Scenes/SutraDetail/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented SutraDetail
> feature. It documents the shipped behavior, including the static mock catalog
> and the sample reading progress.

## User Story

As a practitioner, I want to see a sutra's overview (title, narrator, chapter
count, description, and table of contents) before chanting, so that I can
understand the text and jump into the reader or player.

## Acceptance Criteria (EARS notation)

- WHEN the SutraDetail screen loads for a given sutra id, THE SYSTEM SHALL show
  a dark hero (eyebrow, title, meta line, two info chips, back + download
  buttons), a reading-progress card, the sutra description, and a table of
  contents listing its chapters.
- WHEN the user taps "Tụng theo" (chant) or a chapter in the table of contents,
  THE SYSTEM SHALL open the Reader screen for the same sutra.
- WHEN the user taps the play button in the bottom CTA bar, THE SYSTEM SHALL
  open the full-screen Player for the same sutra.
- WHEN the user taps "Tải về máy" (download), THE SYSTEM SHALL emit a download
  event.
- WHEN the user taps the back control, THE SYSTEM SHALL close the SutraDetail
  screen and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The Reader screen — owned by the Reader feature (`.openReader`).
- The full-screen Player — owned by the Player feature (`.openPlayer`).
- The Download screen — not built (`.download` reaches a TODO in the
  coordinator).

## Pending (not yet implemented — see `tasks.md`)

- A real sutra catalog API. `ILSutraDetailUseCaseImpl` builds a static 1-sutra
  catalog (Kinh Pháp Cú, 5 chapters) with a TODO to replace with `NetworkService`.
  (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the sutra catalog / chapter API contract(s) — no sutra
  > endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- The Download destination (`.download` is a TODO).

- Reading progress is a sample value (`0.34` / "34%") — not connected to any
  real per-user progress.

## Open questions (resolved during implementation)

- ~~Is `.openPlayer` wired or a TODO?~~ → Wired. `ILSutraDetailCoordinator`
  handles `.openPlayer` by pushing `ILPlayerCoordinator` (the README's "TODO"
  note for `.openPlayer` is stale — only `.download` is a real TODO). Resolved
  2026-09-27 by reading the coordinator while writing this spec.
