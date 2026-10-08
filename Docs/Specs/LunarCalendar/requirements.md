# Requirements — LunarCalendar

Version: 1.1
Last updated: 2026-09-30
Status: implemented — 6-month lunar calendar carousel with pure local
computation; no API
Feature folder: `InnerLamp/Presentation/Scenes/LunarCalendar/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented LunarCalendar
> feature. It documents the shipped behavior, including the provisional day-card
> copy and the fast-day-only "upcoming" rows.

## User Story

As a practitioner, I want to view the lunar calendar (with today's solar + lunar
date, fast days, and upcoming special days) across several months, so that I can
track observance days for my practice.

## Acceptance Criteria (EARS notation)

- WHEN the LunarCalendar screen loads, THE SYSTEM SHALL show a 6-month
  horizontally scrollable carousel starting at the current month, where each day
  cell shows the solar day number and the lunar day (with "Mùng 1" / "Rằm"
  labels on those days).
- WHEN the user swipes or taps the ‹ › controls, THE SYSTEM SHALL change the
  displayed month, updating the header to the viewed month/year and its
  lunar-month + Can Chi year subtitle.
- WHEN the user taps a day cell, THE SYSTEM SHALL select that day and update the
  day card below to describe it (eyebrow, title, body), and refresh the
  "upcoming" rows.
- WHEN the day card is shown, THE SYSTEM SHALL display the upcoming fast days /
  new moons / full moons after the selected day (up to 2 rows).
- WHEN the user taps the ✕ close control, THE SYSTEM SHALL close the
  LunarCalendar screen and return to Home.
- WHEN the selected day is today, THE SYSTEM SHALL mark it as today and prefix
  the day-card eyebrow with "Hôm nay".

## Out of scope (this feature boundary, not backend work)

- Temple event / reminder data — the "upcoming" rows are fast days only, not a
  sangha schedule.
- A day-detail screen — selecting a day only updates the day card (the prototype
  has no day-detail screen).

## Pending (not yet implemented — see `tasks.md`)

- Real day-card copy. The day-card title/body are provisional per-category
  strings (`lunarCalendar.hero.*`); the prototype uses per-day content (e.g.
  "Sau lễ Vu Lan Báo Hiếu") that needs product/API confirmation.

  > ⚠️ Not confirmed: the source of per-day content (Buddhist-event API vs
  > static copy) — blocks the day-card copy from matching the prototype.

- The "upcoming" rows are fast days only; the prototype's two sample rows are
  reminder + sangha-event entries (needing bell reminders + a temple-event API)
  and are not interactive.

- The fast-day list (1, 8, 14, 15, 18, 23, 30 lunar) is taken from the
  prototype. Short-month rule (resolved in v1.1): a 29-day lunar month has no
  day 30, so its last day (29) counts as the day-30 fast day. See
  `assumptions.md` (A1).

- Visual QA (carousel height, snap, margins, dark mode) not verified on device.

## Short-month and leap-month rules (v1.1)

- WHEN a lunar month has only 29 days, THE SYSTEM SHALL treat its last day (29)
  as day 30 for fast days, Buddhist event templates and deity memorial days,
  via the shared `ILLunarCalendar.matchesLunarDay`.
- WHEN a day falls in a leap lunar month, THE SYSTEM SHALL NOT fire recurring
  events unless the template has `isLeapMonthEligible`; new-moon and full-moon
  fast days still apply.

## Open questions (resolved during implementation)

- ~~Is the lunar conversion real or hardcoded?~~ → Real — computed by the shared
  `ILLunarCalendar` core utility (`Core/Utils/ILLunarCalendar.swift`), used by
  both the Home week strip and this screen. Resolved during implementation (see
  `Domain/UseCases/LunarCalendar/ILLunarCalendarUseCase.swift`).
