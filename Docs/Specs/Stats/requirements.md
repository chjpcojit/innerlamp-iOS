# Requirements — Stats

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — UI + local logic done (Phases 1–2); real data
integration pending (Phase 3) — `getStats()` currently returns sample data,
no confirmed stats API / local store yet
Feature folder: `InnerLamp/Presentation/Scenes/Stats/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Stats
> feature ("Tiến trình tu tập"), as a worked example of the
> requirements/design/tasks format — see `Docs/Specs/OKF.md` for why and
> when these files are created.

## User Story

As a practitioner viewing my practice progress, I want to see my current
streak (with the next milestone), my total practice time, my usual sit
time, a 12-week duration chart, and my practice-mix breakdown, so that I
can understand my practice trajectory and be nudged to keep my streak via
the mindfulness bell reminder.

## Acceptance Criteria (EARS notation)

- WHEN the Stats screen is shown, THE SYSTEM SHALL display a scrollable
  content area with, in order: a streak featured card (streak days, next
  milestone note + progress bar), a two-tile row (total hours + month
  delta; usual sit time + morning share), a 12-week duration bar chart, a
  practice-mix breakdown, and a mindfulness-bell reminder card.

- WHEN the Stats screen is shown as a child of the Me tab, THE SYSTEM
  SHALL hide the bottom navigation bar and SHALL restore it when the
  screen is left.

- WHEN the user's streak has already earned its next milestone (streak
  days ≥ milestone target) or no next milestone exists, THE SYSTEM SHALL
  hide the milestone note and progress bar on the streak card.

- WHEN the total-hours change versus last month is positive, THE SYSTEM
  SHALL render the tile footnote in the positive (green) tone; otherwise
  (zero or negative) SHALL render it in the neutral tone.

- WHEN no mindfulness bell reminder has been set, THE SYSTEM SHALL show
  the "not set" copy in the reminder card instead of a time summary.

- WHEN there is no weekly data, THE SYSTEM SHALL hide the 12-week chart
  card; WHEN there is no practice mix, THE SYSTEM SHALL hide the
  breakdown card.

- WHEN the user taps the back chip, THE SYSTEM SHALL pop back to the
  previous screen.

- WHEN the user taps the mindfulness-bell reminder card, THE SYSTEM SHALL
  emit an open-reminder navigation event.

## Out of scope (this feature boundary, not backend work)

- Mindfulness bell reminder configuration (`remind` screen) — a separate,
  not-yet-built feature; Stats only links to it via `.openReminder`.
- The other entry points shown in the design handoff (Home streak card,
  Journal detail "Xem tiến trình", Awards bottom button) — wiring those
  screens to Stats is separate work, not part of this feature.

## Pending (not yet implemented)

- Real data: `ILStatsUseCaseImpl.getStats()` returns hardcoded sample
  data — no confirmed stats API / local store yet (tracked in `tasks.md`
  Phase 3).

  > ⚠️ Not confirmed: the exact stats data contract — whether stats are
  > served by a backend API, stored local-first then synced, or both, and
  > the field shapes each source provides — blocks `tasks.md` Phase 3 from
  > being implementable.

- Error / offline rendering: the `.failure` state is a TODO in
  `ILStatsViewController` — irrelevant until a real repository exists.
- `.openReminder` destination: the mindfulness bell reminder (`remind`)
  screen is not built yet, so the coordinator currently ignores the event
  (see Out of scope above).

## Open questions (resolved during implementation)

- (none yet)
