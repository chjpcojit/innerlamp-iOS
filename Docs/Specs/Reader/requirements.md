# Requirements — Reader

Version: 1.1
Last updated: 2026-10-03
Status: in-progress — scrolling line-by-line chant view (themes, font sizes,
auto-scroll, pace chips) with a static catalog and a simulated playback timer;
no sutra API and no real audio
Feature folder: `InnerLamp/Presentation/Scenes/Reader/`

> See `changelog.md` in this folder for the version history of this spec.

> v1.1 follows the refreshed design handoff (`Docs/InnerLamp project/`, block
> `isReader`): the verse-by-verse view with a floating playback bar was replaced
> by a full scrolling chant text.

## User Story

As a practitioner, I want to read a sutra line by line, following a highlighted
current line with bell/wooden-fish cues, in a font size and background I choose,
so that I can chant along comfortably.

## Acceptance Criteria (EARS notation)

- WHEN the Reader screen loads for a sutra id, THE SYSTEM SHALL show the sutra
  title, a status line, the chant text (the shared "KHAI KINH" opening followed
  by the sutra body, in headed sections), the line 0 highlighted, and the bottom
  controls. WHEN the sutra has audio, it SHALL start playing.
- WHEN the sutra has audio, THE SYSTEM SHALL show the status "Đang tụng ·
  <narrator>" while playing and "Tạm dừng · chạm để tụng tiếp" while paused, and
  the position / progress / duration row; otherwise it SHALL show "Chỉ có văn
  bản", hide that row and label the pace control "Tốc độ cuộn".
- WHILE playing, THE SYSTEM SHALL advance the highlighted line every 2.6 s at
  1.0× (scaled by the selected pace) and pause on the last line.
- WHEN the current line changes and "Tự cuộn" is on, THE SYSTEM SHALL scroll so
  the line sits at about 38% of the visible list height.
- WHEN the user taps the "Tự cuộn" pill, THE SYSTEM SHALL toggle auto-scroll.
- WHEN the user taps the chant text, THE SYSTEM SHALL close the settings panel
  if it is open, otherwise toggle play/pause.
- WHEN the user taps play/pause, THE SYSTEM SHALL toggle playback.
- WHEN the user taps −10s / +10s, THE SYSTEM SHALL move the highlight 2 lines
  back / forward (clamped to the first / last line).
- WHEN the user taps a pace chip (1x, 1.2x, 1.5x), THE SYSTEM SHALL select it.
- WHEN the user taps "Aa", THE SYSTEM SHALL show or hide the settings panel with
  "Cỡ chữ" (4 sizes: 17/20/23/26) and "Màu nền" (Mặc định, Vàng cát, Đen OLED).
- WHEN the user selects a size or background, THE SYSTEM SHALL re-render the
  chant text and screen with it.
- WHILE the Reader is visible, THE SYSTEM SHALL keep the screen awake.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Reader screen
  and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The full-screen player — owned by the Player feature; no longer reachable from
  the Reader in the refreshed design.
- Share / offline-download entry points — removed from the Reader in the
  refreshed design.

## Pending (not yet implemented — see `tasks.md`)

- A real sutra/catalog API. `ILReaderUseCaseImpl` builds a static 11-sutra
  catalog with chant text only for Kinh Pháp Cú and Bát Nhã Tâm Kinh (others
  show a "text coming soon" placeholder). (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the sutra catalog / chant-text API contract(s) — no
  > reader endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md`
  > Phase 3.

- Real audio. The highlight is driven by a timer; no recitation file is played.
- Entering at a chosen chapter/part (the prototype starts at line 5 or 6 for
  some entries); the Reader always starts at line 0.
- Persisting the chosen font size / background / auto-scroll across launches
  (state is in-memory).

## Open questions (resolved during implementation)

- ~~How is the sutra resolved when the id is unknown?~~ → Fallback to the first
  catalog sutra (Kinh Pháp Cú).
