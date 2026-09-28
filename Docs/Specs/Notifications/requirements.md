# Requirements — Notifications

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full UI with mock data; no notifications/push API, and
the "Ngồi ngay" destination is a TODO
Feature folder: `InnerLamp/Presentation/Scenes/Notifications/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Notifications
> feature. It documents the shipped behavior, including the static mock data and
> the unimplemented "Ngồi ngay" destination.

## User Story

As a practitioner, I want to see my notifications and an upcoming practice
session, so that I can stay on top of bell reminders, sangha events, community
interactions, and offering receipts.

## Acceptance Criteria (EARS notation)

- WHEN the Notifications screen loads, THE SYSTEM SHALL show a header (serif
  title + "Đóng"), an "upcoming" hero card (when one exists) with two pills
  ("Ngồi ngay" / "Bỏ qua tối nay"), a "HÔM NAY" section eyebrow, and a list of
  notification rows (tinted icon tile, title + relative time, body, unread dot).
- WHEN the user taps "Bỏ qua tối nay", THE SYSTEM SHALL dismiss the hero card.
- WHEN the user taps "Ngồi ngay", THE SYSTEM SHALL emit an open-setup event.
- WHEN the user taps "Đóng", THE SYSTEM SHALL close the Notifications screen and
  return to the previous screen.
- WHEN a notification is unread, THE SYSTEM SHALL show an unread indicator; WHEN
  it is read, THE SYSTEM SHALL not show the indicator.

## Out of scope (this feature boundary, not backend work)

- The MeditationSetup screen (`.openSetup` reaches a TODO in the coordinator).

## Pending (not yet implemented — see `tasks.md`)

- A real notifications/push API. `ILNotificationsUseCaseImpl.getUpcoming()` /
  `getNotifications()` return static mock data with TODOs to replace with
  `ILNotificationsRepository` (network + push payload). (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the notifications / push / upcoming-session API contract(s)
  > — no notifications endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks
  > `tasks.md` Phase 3.

- Mark-as-read: `isRead` is static; there is no mark-as-read flow.
- The "Ngồi ngay" destination is a TODO (the MeditationSetup screen now exists,
  so this can be wired — see the resolved open question below).
- `.failure` renders nothing (no network-backed source yet).

## Open questions (resolved during implementation)

- ~~Is the "Ngồi ngay" destination built?~~ → The README says "setup not built",
  but the MeditationSetup feature (and its `ILMeditationSetupCoordinator`) **is**
  now implemented. `.openSetup` is still a TODO in `ILNotificationsCoordinator`,
  so it should be wired to `showMeditationSetup()` — a real pending task, not a
  blocked one. Resolved 2026-09-27 by reading the code while writing this spec.
