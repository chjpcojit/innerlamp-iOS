# Requirements — LunarDayDetail

Version: 2.0
Last updated: 2026-10-07
Status: lunar data implemented (pure client-side computation); hero image from
`GET /v1/calendar/image` specified, implementation pending
Feature folder: `InnerLamp/Presentation/Scenes/LunarDayDetail/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented LunarDayDetail
> feature (built by `ui-builder` from the design handoff), as documentation
> of what shipped — see `references/modes.md`.

## User Story

As a practitioner on the Home screen, I want to open the detail of a lunar
calendar day (the large lunar card) so that I can see that day's full lunar
data — day/month/year can-chi, day type, advice, verse of the day, auspicious
hours, clash ages, and travel directions — computed from the selected solar date.

## Acceptance Criteria (EARS notation)

- WHEN the LunarDayDetail screen loads, THE SYSTEM SHALL compute and display the
  full lunar data for the solar `Date` passed in from the Home lunar card, with
  no network access (all values derived from `ILLunarCalendar`; the hero image
  below is the only server-backed content and never gates this data).
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
  name, meaning, and Hán glyph (喜 / 財), plus the Hạc thần (crane star)
  direction to avoid (Hán glyph 鶴); on the 16 of 60 can-chi days when Hạc thần
  is "in heaven", THE SYSTEM SHALL show "Trên trời" with the note "Không kỵ hướng
  nào". The three cards sit in one 3-column row (matching the design handoff);
  the design labels the third card "Hắc thần", the app keeps the traditional
  name "Hạc thần" (鶴神).
- WHEN the screen renders the advice line, THE SYSTEM SHALL show a rule-based
  advice label per the lunar day: Mùng Một / Rằm as "ngày trai giới", days 8 /
  14 / 23 / 30 as "ngày trai", and everything else as "ngày thường".
- WHEN the header is scrolled past 110 px, THE SYSTEM SHALL transition the
  transparent header to an opaque background.
- WHEN the LunarDayDetail screen loads, THE SYSTEM SHALL request the hero image
  for the screen's solar date with `GET /v1/calendar/image?date=YYYY-MM-DD`
  (public, no `Authorization`), in parallel with — and without delaying — the
  local lunar data above.
- WHEN the hero image response arrives, THE SYSTEM SHALL show the image as the
  hero background (aspect-fill, under a scrim that fades into the page canvas so
  the lunar day, solar date, day-type pill and advice line stay legible in light
  and dark mode) and SHALL show an attribution line "Ảnh: <author> · <license>".
- THE SYSTEM SHALL pass the solar date explicitly (`yyyy-MM-dd`, Gregorian
  components of the screen's `Date`), SHALL use the returned `image_url` verbatim
  (never rebuilding its host), and SHALL show the same image for the same date.
- IF the screen's solar year is outside 1900–2100, THEN THE SYSTEM SHALL NOT
  call the endpoint and SHALL keep the gradient hero.
- IF the image request fails (offline, `400 INVALID_DATE`, server error,
  malformed payload) or the image URL itself fails to load, THEN THE SYSTEM SHALL
  keep the gradient hero, hide the attribution line, and SHALL NOT show an error
  or block any other section of the screen.
- WHEN the user taps the back (‹) button, THE SYSTEM SHALL pop back to the Home
  screen and finish this feature's coordinator.

## Out of scope (this feature boundary, not backend work)

- The Home lunar card and the week calendar that navigate here — owned by the
  Home feature (`Docs/Specs/Home/`).
- The full Lunar Calendar month carousel screen ("Lịch âm") — owned by the
  LunarCalendar feature (`Docs/Specs/LunarCalendar/`).
- Any server-backed "verse of the day" / daily-teaching API — not in this
  feature (see Pending).
- Showing the calendar image on the LunarCalendar month screen ("Lịch âm") —
  only the day-detail hero uses it (see resolved question 2026-10-07).
- A tappable attribution / license link (see `tasks.md` Phase 4 and
  `Docs/Tech-Debt/LunarDayDetail/`).

## Pending (not yet implemented — see `tasks.md`)

- Real hero cover imagery — specified in v2.0 (server image per date, see the
  acceptance criteria above); implementation is tracked in `tasks.md` Phase 3.
  The gradient stays as the placeholder and as the failure fallback.

  > ⚠️ Not confirmed: whether the attribution line may stay plain text, or the
  > CC BY / CC BY-SA licenses require a tappable link (`license_url` /
  > `source_url`) — blocks legal sign-off, not the build. Recorded as
  > `TD-LunarDayDetail-001`.
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
  `ui-builder` build.
- ~~Which screen is "trang ngày âm" for the new calendar image?~~ → The
  LunarDayDetail ("Chi tiết ngày âm") hero, which already had a ⚠️ pending image
  slot and receives a solar `Date`. Resolved 2026-10-07 by interpreting the
  request; recorded as `AS-LunarDayDetail-002` (Unvalidated).
- ~~Does the backend serve a lunar-calendar image?~~ → Yes, as of 2026-10-07:
  `GET /v1/calendar/image?date=YYYY-MM-DD` (`[BE]-InnerLamp`). Contract in
  `design.md` → "API contract".
