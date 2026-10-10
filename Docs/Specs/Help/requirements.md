# Requirements — Help

Version: 2.0
Last updated: 2026-10-10
Status: not started — prospective; FAQ content is bundled mock, backend contract unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Help/`

> See `changelog.md` in this folder for the version history of this spec.
> Source of truth for business intent: `SRS.md` in this folder.

## User Story

As a practitioner, I want to find answers to common questions, so that I can
resolve an issue myself without waiting for support.

## Acceptance Criteria (EARS notation)

- WHEN the Help screen loads, THE SYSTEM SHALL show the intro ("Bạn đang cần
  giúp điều gì?") as a search field and the FAQ questions as collapsed cards, in
  the order given by the content source. (FR-001)
- WHEN the user taps a collapsed question, THE SYSTEM SHALL expand its answer
  (gold border, rotated arrow) and collapse any other open question. (FR-002)
- WHEN the user taps the open question, THE SYSTEM SHALL collapse it so that no
  answer is visible. (FR-002)
- WHEN the user taps the search field, THE SYSTEM SHALL open the Search screen.
  (FR-003)

  > ⚠️ Not confirmed: whether the Search screen exists in the iOS app by this
  > release and whether it is pre-scoped to help content — until then the
  > search field is inert (`.openSearch` is a TODO in the coordinator).

- WHEN the user taps the footer button ("Gửi thư cho ban hỗ trợ"), THE SYSTEM
  SHALL open the Contact Support screen. (FR-004)
- WHEN the FAQ content cannot be loaded, THE SYSTEM SHALL show an error state
  with a retry action instead of an empty list. (FR-005)

  > ⚠️ Not confirmed: wording/design of the empty and failure states —
  > blocks final copy; the shared `IL-State` look is assumed.

- WHEN the user taps back, THE SYSTEM SHALL pop Help and return to Settings.

## Out of scope (this feature boundary, not backend work)

- The Settings row that navigates here — owned by Settings (`openHelp`).
- The Search screen opened from the search field.
- The Contact Support screen (`Docs/Specs/ContactSupport/`).

## Pending (not yet implemented — see `tasks.md`)

- FAQ API. Content is a bundled mock behind a Repository so the real source can
  replace it.

  > ⚠️ Not confirmed: FAQ API contract (endpoint, fields, language handling) —
  > blocks `tasks.md` Phase 3.

- Search entry (see ⚠️ above).

## Open questions (resolved during implementation)

- ~~FAQ set: prototype (free, no plans) or old spec (with "gia hạn Sen Vàng")?~~
  → Prototype's 5-item set (2026-10-10). The old "gia hạn Sen Vàng" question
  is dropped.
- ~~FAQ content source: bundled or backend?~~ → Bundled mock for now; API
  supplied later by the product owner (2026-10-10).
- ~~Name of the support team~~ → "Ban hỗ trợ" everywhere (2026-10-10).
