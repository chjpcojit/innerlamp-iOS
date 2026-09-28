# Requirements — Library

Version: 2.0
Last updated: 2026-09-27
Status: in-progress — UI + local filtering implemented against a mock catalog;
Library is now a tab of `ILMainTabCoordinator`; catalog API not confirmed
Feature folder: `InnerLamp/Presentation/Scenes/Library/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the implemented Library feature (v1.x
> was prospective). It reflects the shipped behavior, including that Library is
> a root tab (not an `AppCoordinator`-owned root screen as v1.x assumed).

## User Story

As a practitioner, I want to browse a library of sutras, guided meditations and
dharma talks from one tab, so that I can quickly find something to chant or
listen to and open it.

## Acceptance Criteria (EARS notation)

### Layout

- WHEN the Library tab loads, THE SYSTEM SHALL show, top to bottom: a pinned
  title "Thư viện", a tap-only search bar, a row of four category chips (Tất cả
  / Kinh văn / Thiền dẫn / Pháp thoại), one featured dark card, and a section
  title with a list of content rows. The bottom navigation bar is owned by
  `ILMainTabBarController` (Library is tab 2), not by this screen.
- WHEN the screen loads, THE SYSTEM SHALL preselect the "Tất cả" chip.
- WHEN the content is taller than the viewport, THE SYSTEM SHALL scroll the
  search bar, chips, featured card and list while keeping the title pinned.
- WHEN the device is in dark mode, THE SYSTEM SHALL render the screen with the
  dark token set (canvas, card, ink) — the featured card stays dark in both
  modes (per design handoff "always dark" hero cards).

### Category filter

- WHEN the user taps a category chip that is not selected, THE SYSTEM SHALL mark
  that chip as selected, deselect the previous one, and show only the content
  rows belonging to that category ("Tất cả" shows every kind).
- WHEN the user taps the already-selected chip, THE SYSTEM SHALL keep the
  current selection and list unchanged.
- WHEN the selected category has no content, THE SYSTEM SHALL replace the list
  with the empty state instead of a blank area.
- WHEN the category changes, THE SYSTEM SHALL update the list section title to
  match the category ("Thường nghe & tụng" / "Kinh thường tụng" / "Thiền dẫn
  thường dùng" / "Pháp thoại mới").
- WHEN the category changes, THE SYSTEM SHALL leave the featured card unchanged.

### Content rows

- WHEN a content row is shown, THE SYSTEM SHALL display its title, its one-line
  subtitle, a trailing duration, and a tone-coloured book glyph tile.
- WHEN the duration is under 60 minutes, THE SYSTEM SHALL format it as "<n>
  phút"; WHEN it is 60 minutes or more, THE SYSTEM SHALL format it as "<h>g
  <m>p", omitting the minutes part when it is 0.
- WHEN the user taps a content row, THE SYSTEM SHALL emit a navigation event
  carrying the item id and kind so the owning coordinator can open the matching
  detail screen.

### Featured card

- WHEN the featured card is shown, THE SYSTEM SHALL display its eyebrow in caps,
  its serif title, and a pill button "Nghe · <duration>".
- WHEN the user taps anywhere on the featured card, THE SYSTEM SHALL emit a
  navigation event carrying the featured item id and kind `.talk`, so the
  coordinator can open the dharma talk screen.
- WHEN no featured item is available, THE SYSTEM SHALL hide the featured card
  and keep the rest of the screen intact.

### Search

- WHEN the user taps the search bar, THE SYSTEM SHALL emit a search navigation
  event (the bar is a tap target, not an editable field — the Search screen owns
  text input).

### Copy

- THE SYSTEM SHALL read every user-facing string from the JSON localization
  system (`"library.*"` keys in `vi.json`); no string literal in code.

## Out of scope (this feature boundary, not backend work)

- The Search screen, Sutra detail, Reader, Dharma talk and Player screens — each
  owns its own spec. Library emits navigation events toward them (and, for
  sutras, opens SutraDetail).
- Loading skeleton, error and offline full-screen states — owned by the shared
  system-state work.
- Downloads / offline listening.

## Pending (not yet implemented — see `tasks.md`)

- Real catalog data (sutras, meditations, talks, featured item) — Phase 3.
  > ⚠️ Not confirmed: Which backend endpoint(s) serve the library catalog, and
  > what is the request/response shape (pagination? categories? featured item)?
  > — blocks Phase 3 (DTO, Mapper, Endpoint, Repository).
- Destination mapping for `.meditation` and `.talk` items, and the featured
  card (`.talk`), are still TODO in the coordinator; the Search screen is also
  TODO. Only `.sutra` (→ SutraDetail) is wired.
  > ⚠️ Not confirmed: Which screen does a meditation item open (Setup/Session?)
  > and a talk item open (Talk?) — the prototype wires every row to `detail` and
  > the featured card to `talk`; meditation rows have no designed destination.
  > Blocks the coordinator navigation mapping for those kinds.

## Open questions (resolved during implementation)

- ~~Is Library an `AppCoordinator` root screen with its own bottom bar?~~ → No.
  Library is **tab 2 of `ILMainTabBarController`** (owned by
  `ILMainTabCoordinator`), so tab switching is handled by the tab bar, the
  `ILLibraryCoordinatorDelegate`/`goHome` delegate is gone, and the screen no
  longer embeds `ILBottomNavBar`. Resolved during implementation (v1.x assumed
  the AppCoordinator-root shape; the code shipped as a tab).
- ~~What are the per-category section titles?~~ → Confirmed: Tất cả → "Thường
  nghe & tụng", Kinh văn → "Kinh thường tụng", Thiền dẫn → "Thiền dẫn thường
  dùng", Pháp thoại → "Pháp thoại mới" (`library.section.all/sutra/meditation/
  talk` in `vi.json`). Resolved during implementation (see
  `ILLibraryViewModel.sectionTitle(for:)`).
