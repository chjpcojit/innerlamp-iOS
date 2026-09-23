# Requirements — Library

Version: 1.1
Last updated: 2026-09-20
Status: in-progress — UI + local logic implemented against a mock catalog; backend catalog API not confirmed
Feature folder: `InnerLamp/Presentation/Scenes/Library/`

> See `changelog.md` in this folder for the version history of this spec.

> Prospective spec, derived from the design handoff screen `lib` ("Thư viện") in
> `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html` (`isLib`, ~line 651) and the
> `sutras` sample data (~line 3131).

## User Story

As a practitioner, I want to browse a library of sutras, guided meditations and dharma talks from
one tab, so that I can quickly find something to chant or listen to and open it.

## Acceptance Criteria (EARS notation)

### Layout

- WHEN the Library screen loads, THE SYSTEM SHALL show, top to bottom: a pinned title "Thư viện",
  a search bar, a row of four category chips (Tất cả / Kinh văn / Thiền dẫn / Pháp thoại), one
  featured dark card, a section title with a list of content rows, and the bottom navigation bar
  with the Library tab active.
- WHEN the screen loads, THE SYSTEM SHALL preselect the "Tất cả" chip.
- WHEN the content is taller than the viewport, THE SYSTEM SHALL scroll the search bar, chips,
  featured card and list while keeping the title and the bottom navigation bar pinned.
- WHEN the device is in dark mode, THE SYSTEM SHALL render the screen with the dark token set
  (canvas, card, ink) — the featured card stays dark in both modes (per design handoff "always
  dark" hero cards).

### Category filter

- WHEN the user taps a category chip that is not selected, THE SYSTEM SHALL mark that chip as
  selected, deselect the previous one, and show only the content rows belonging to that category
  ("Tất cả" shows every kind).
- WHEN the user taps the already-selected chip, THE SYSTEM SHALL keep the current selection and
  list unchanged.
- WHEN the selected category has no content, THE SYSTEM SHALL replace the list with the shared
  empty state instead of a blank area.
- WHEN the category changes, THE SYSTEM SHALL update the list section title to match the category
  (see the ⚠️ item under "Pending" for the title copy).
- WHEN the category changes, THE SYSTEM SHALL leave the featured card unchanged.

### Content rows

- WHEN a content row is shown, THE SYSTEM SHALL display its title, its one-line subtitle (e.g.
  "423 kệ · song ngữ"), a trailing duration, and a tone-coloured book glyph tile.
- WHEN the duration is under 60 minutes, THE SYSTEM SHALL format it as "<n> phút"; WHEN it is 60
  minutes or more, THE SYSTEM SHALL format it as "<h>g <m>p" (e.g. 130 minutes → "2g 10p"),
  omitting the minutes part when it is 0.
- WHEN the user taps a content row, THE SYSTEM SHALL emit a navigation event carrying the item id
  and kind so the owning coordinator can open the matching detail screen.

### Featured card

- WHEN the featured card is shown, THE SYSTEM SHALL display its eyebrow in caps, its serif title
  (may span two lines) and a pill button "Nghe · <duration>".
- WHEN the user taps anywhere on the featured card, THE SYSTEM SHALL emit a navigation event
  carrying the featured item id, so the coordinator can open the dharma talk screen.
- WHEN no featured item is available, THE SYSTEM SHALL hide the featured card and keep the rest
  of the screen intact.

### Search & navigation

- WHEN the user taps the search bar, THE SYSTEM SHALL emit a search navigation event (the bar is
  a tap target, not an editable field — the Search screen owns text input).
- WHEN the user taps the "Trang chủ" tab in the bottom navigation, THE SYSTEM SHALL navigate to
  the Home screen.
- WHEN the user taps the Library tab, THE SYSTEM SHALL do nothing (already active).
- WHEN the user taps the Lamp, Sangha or Me tab, THE SYSTEM SHALL do nothing until those screens
  exist (see "Pending").
- WHEN the user taps the "Thư viện" tab on the Home screen, THE SYSTEM SHALL navigate to the
  Library screen with a crossfade transition.

### Copy

- THE SYSTEM SHALL read every user-facing string from the JSON localization system
  (`"library.*"` keys in `vi.json`); no string literal in code.

## Out of scope (this feature boundary, not backend work)

- The Search screen (`search`, `empty`), Sutra detail (`detail`), Reader (`reader`), Dharma talk
  (`talk`) and Player (`player`) screens — each owns its own spec. Library only emits navigation
  events toward them.
- Loading skeleton, error and offline full-screen states (`loading`, `error`, `offline` in the
  design handoff) — owned by the shared system-state work, not by this screen.
- Downloads / offline listening (`downloads`).
- The Lamp, Sangha and Me tab destinations.

## Pending (not yet implemented — see `tasks.md`)

- Real catalog data (sutras, meditations, talks, featured item) — Phase 3.
  > ⚠️ Not confirmed: Which backend endpoint(s) serve the library catalog, and what is the
  > request/response shape (pagination? categories? featured item)? — blocks Phase 3 (DTO,
  > Mapper, Endpoint, Repository).
- Row/featured/search taps currently end in a coordinator TODO because the destination screens
  do not exist yet — tracked as Deferred in `tasks.md`.
  > ⚠️ Not confirmed: Which screen does each item kind open (sutra → Detail, meditation →
  > Setup/Session, talk → Talk)? The prototype wires every row to `detail` and the featured card
  > to `talk`; meditation rows have no designed destination — blocks the coordinator navigation
  > mapping.
- List section title copy per category.
  > ⚠️ Not confirmed: The prototype only shows "Kinh thường tụng" for the default state and
  > designs no filtered state or other section titles. Assumed: Tất cả → "Thường nghe & tụng",
  > Kinh văn → "Kinh thường tụng", Thiền dẫn → "Thiền dẫn thường dùng", Pháp thoại → "Pháp thoại
  > mới" — blocks final copy in `vi.json`.
- Tab destinations Lamp / Sangha / Me — blocked by the Setup, Sangha and Profile specs.

## Open questions (resolved during implementation)

- None yet.
