# Requirements — Events

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — UI + tab logic done with mock data; no events API, and
the Register destination is not built
Feature folder: `InnerLamp/Presentation/Scenes/Events/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Events
> feature. It documents the shipped behavior, including the fact that all data
> is mock and the Register destination is a TODO.

## User Story

As a practitioner, I want to browse upcoming Buddhist events and courses (and
see the ones I've registered for), so that I can find and join practices.

## Acceptance Criteria (EARS notation)

- WHEN the Events screen loads, THE SYSTEM SHALL show a 3-tab selector
  (Sắp diễn ra / Khóa học / Đã ghi danh), a dark featured "Sắp diễn ra" hero
  card, and a list of events for the selected tab.
- WHEN the user switches tabs, THE SYSTEM SHALL show the corresponding list —
  upcoming events, courses, or registered events — with the section title
  updated to match.
- WHEN the list for a tab is empty, THE SYSTEM SHALL show an empty state (the
  list has no items).
- WHEN the user taps "Ghi danh" (the hero CTA) or an event row, THE SYSTEM
  SHALL emit an open-register event carrying the event id.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Events screen
  and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The Register screen itself (`.openRegister` reaches a TODO in the coordinator;
  the `register` screen is not built).

## Pending (not yet implemented — see `tasks.md`)

- A real events API. `ILEventsUseCaseImpl.getEvents()` returns static mock data
  (featured, upcoming, courses, registered) with a TODO to replace with
  `NetworkService` once a contract exists. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the events/courses/registrations API contract(s) — no
  > events endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md`
  > Phase 3.

- The Register destination. Tapping "Ghi danh" only emits `.openRegister(eventId:)`;
  the coordinator has a `// TODO` and does not navigate yet.

- Loading / error / offline states are not rendered — data is local mock, so
  `.failure` only surfaces a generic alert.

## Open questions (resolved during implementation)

- ~~Is the featured hero shown per-tab?~~ → No, the featured "Sắp diễn ra" hero
  is always shown regardless of the selected tab (matches the prototype); only
  the list below it changes per tab. Resolved during implementation (see
  `Presentation/Scenes/Events/README.md`).
