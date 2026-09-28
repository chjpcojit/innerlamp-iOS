# Requirements — LunarDayDetail

Version: 1.0
Last updated: 2026-09-27
Status: implemented — pure client-side lunar computation, no backend; only visual
QA and a few copy/asset confirmations remain open
Feature folder: `InnerLamp/Presentation/Scenes/LunarDayDetail/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented LunarDayDetail
> feature (built by `il-screen-builder` from the design handoff), as documentation
> of what shipped — see `references/modes.md`.

## User Story

As a practitioner on the Home screen, I want to open the detail of a lunar
calendar day (the large lunar card) so that I can see that day's full lunar
data — day/month/year can-chi, day type, advice, verse of the day, auspicious
hours, clash ages, and travel directions — computed from the selected solar date.

## Acceptance Criteria (EARS notation)

- WHEN the LunarDayDetail screen loads, THE SYSTEM SHALL compute and display the
  full lunar data for the solar `Date` passed in from the Home lunar card, with
  no network or disk access (all values derived from `ILLunarCalendar`).
- WHEN the screen renders the hero, THE SYSTEM SHALL show the lunar day number,
  the lunar month label (with a "nhuận" marker when it is a leap month), the
  lunar year's can-chi, and the full solar date as the subtitle.
- WHEN the screen renders the day-type pill, THE SYSTEM SHALL label the day as
  Hoàng đạo / Hắc đạo, or Rằm / Mùng Một (both toned gold), based on the
  computed lunar day and the Hoàng đạo flag.
- WHEN the screen renders the info table, THE SYSTEM SHALL show four rows —
  day can-chi, month can-chi, year can-chi, and the solar date.
- WHEN the screen renders the verse of the day, THE SYSTEM SHALL show the verse
  content and its source, selected by the static `(lunarDay + lunarMonth) % 4`
  catalog index.
- WHEN the screen renders the auspicious hours, THE SYSTEM SHALL list the six
  good hours for the day's earthly branch, each with its branch name, zodiac
  animal, and two-hour range.
- WHEN the screen renders the clash ages, THE SYSTEM SHALL show the two clash
  ages derived from the day's heavenly stem and the opposing earthly branch,
  plus an explanatory note naming the day's can-chi and the clashing branch.
- WHEN the screen renders the travel directions, THE SYSTEM SHALL show the Hỷ
  thần (joy star) and Tài thần (wealth star) directions with their Vietnamese
  name, meaning, and Hán glyph (喜 / 財).
- WHEN the screen renders the advice line, THE SYSTEM SHALL show a rule-based
  advice label per the lunar day: Mùng Một / Rằm as "ngày trai giới", days 8 /
  14 / 23 / 30 as "ngày trai", and everything else as "ngày thường".
- WHEN the header is scrolled past 110 px, THE SYSTEM SHALL transition the
  transparent header to an opaque background.
- WHEN the user taps the back (‹) button, THE SYSTEM SHALL pop back to the Home
  screen and finish this feature's coordinator.

## Out of scope (this feature boundary, not backend work)

- The Home lunar card and the week calendar that navigate here — owned by the
  Home feature (`Docs/Specs/Home/`).
- The full Lunar Calendar month carousel screen ("Lịch âm") — owned by the
  LunarCalendar feature (`Docs/Specs/LunarCalendar/`).
- Any server-backed "verse of the day" / daily-teaching API — not in this
  feature (see Pending).

## Pending (not yet implemented — see `tasks.md`)

- Real hero cover imagery — the prototype's image slot is rendered as a
  `--il-sunk2 → --il-tint → --il-canvas` gradient placeholder; a real
  temple/moon/lotus image needs to come from the product side
  (`tasks.md` Phase 4).

  > ⚠️ Not confirmed: whether the hero stays a gradient or gets a real image
  > asset, and what that asset is — blocks the final hero visual.
- Non-Vietnamese localization of the can-chi / direction / month labels —
  currently only `vi.json` is populated; English / 中文 fall back to the key.
- Visual QA on simulator/device — build + unit tests have not been re-run since
  the feature was added; the 72px hero, gradient, dark mode, and header
  transition still need a real look.

  > ⚠️ Not confirmed: final position/copy of the advice line (added per
  > `Mo-ta-tinh-nang.md`, but the prototype computed `dcNote` without rendering
  > it) — blocks a design-accurate advice placement.
  >
  > ⚠️ Not confirmed: whether the zodiac animals stay as emoji (🐀…🐖) or are
  > replaced by a dedicated vector icon set.

## Open questions (resolved during implementation)

- ~~Should this be a standalone scene or part of Home?~~ → Standalone leaf scene
  owned by `ILHomeCoordinator`, reached via
  `ILHomeNavEvent.openLunarDayDetail(date:)`. Resolved 2026-09-27 by the
  `il-screen-builder` build.
