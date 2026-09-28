# Requirements — Awards

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; awards-data source unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Awards/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner, I want to see my practice achievements (Dấu ấn tu tập) as a
set of badges, so that I can track which milestones I have reached and what I am
working toward.

## Acceptance Criteria (EARS notation)

- WHEN the Awards screen loads, THE SYSTEM SHALL show the header with the
  progress ("Dấu ấn tu tập · 6 trong 18 dấu ấn").
- WHEN the screen renders the recent-badge card, THE SYSTEM SHALL show the most
  recently earned badge ("Dấu ấn gần nhất · An cư bốn mươi ngày").
- WHEN the screen renders the badge grid, THE SYSTEM SHALL show all 18 badges in
  a 3-column grid; earned badges are full-color with a "Đã đạt / Mới đạt"
  subtitle, and unearned badges are 50%-dimmed with a dashed border and a
  progress subtitle ("Còn 58 ngày", "Còn 2 giờ", "Chưa mở").
- WHEN the screen loads, THE SYSTEM SHALL keep a fixed bottom "Xem tiến trình tu
  tập" button; tapping it SHALL navigate to Stats.

## Out of scope (this feature boundary, not backend work)

- The Profile "Dấu ấn tu tập" preview that navigates here — owned by the Profile
  feature.
- The Stats screen reached from the bottom button — owned by the Stats feature.
- The rule engine that computes which badges are earned (assumed shared with
  Stats).

## Pending (not yet implemented — see `tasks.md`)

- Awards data source (list of badges + which are earned + progress).

  > ⚠️ Not confirmed: whether badges/progress are computed locally from practice
  > stats or fetched from a backend — blocks `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->
