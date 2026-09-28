# Requirements — Journal

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-first (sync source unconfirmed)
Feature folder: `InnerLamp/Presentation/Scenes/Journal/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner, I want to keep a daily practice journal — list my entries,
write a new one, and review a single day — so that I can reflect on my practice
over time.

## Acceptance Criteria (EARS notation)

### Journal list

- WHEN the Journal list loads, THE SYSTEM SHALL show a header ("Nhật ký" + a
  "Lịch âm" action) and a "Thời lượng theo tuần" card with 7 day columns
  (T2–CN) shaded by duration, plus the weekly average ("TB 22 phút/ngày").
- WHEN the list renders entries, THE SYSTEM SHALL show each recorded day with
  date, title, summary, and a color tag for the practice type (Tụng kinh /
  Thiền / Niệm Phật).
- WHEN the user taps an entry, THE SYSTEM SHALL open the entry detail.
- WHEN the user taps "Ghi lại hôm nay", THE SYSTEM SHALL open the write screen.
- WHEN the user taps "Lịch âm" in the header, THE SYSTEM SHALL open the Lunar
  Calendar screen.

### Journal write

- WHEN the write screen loads, THE SYSTEM SHALL show the header ("Nhật ký hôm
  nay" + "Lưu"), the solar date ("10 TH9"), the lunar date ("16 tháng Bảy âm ·
  sau ngày rằm"), a text area with a character counter, and tag chips (Thiền,
  Niệm Phật, Tụng kinh, + Thẻ mới).
- WHEN the user taps "Lưu vào nhật ký", THE SYSTEM SHALL save the entry and
  return to the Journal list.
- WHEN the user selects tags, THE SYSTEM SHALL support multi-select; the
  selected tags are highlighted.

### Journal entry detail

- WHEN the entry detail loads, THE SYSTEM SHALL show the header ("09 tháng 9 ·
  16 tháng Bảy âm · Rằm Vu Lan" + "Sửa"), a "Thời khóa đã tròn" card, the mood,
  the dedication, the tags, and the written content.
- WHEN the screen renders "Đã hành trong ngày", THE SYSTEM SHALL list the day's
  practice items (e.g. "Kinh Vu Lan Báo Hiếu", "Niệm Phật 3 tràng"), each with an
  "Mở" action.
- WHEN the user taps "Sửa" or "Viết thêm", THE SYSTEM SHALL open the write screen
  for that entry.
- WHEN the user taps a practice item, THE SYSTEM SHALL open the corresponding
  screen (a sutra → SutraDetail, Niệm Phật → Mala).
- WHEN the user taps "Xem tiến trình", THE SYSTEM SHALL open Stats.

## Out of scope (this feature boundary, not backend work)

- The Home "Thời khóa / chuỗi ngày", Profile "Nhật ký", and Stats navigation
  that reach here — owned by those features.
- SutraDetail, Mala, Stats, and LunarCalendar screens reached from Journal.
- The SessionComplete screen that saves into the journal.

## Pending (not yet implemented — see `tasks.md`)

- Journal persistence model — the design specifies **local-first** (journal is
  written locally then synced), but the sync backend is unconfirmed.

  > ⚠️ Not confirmed: whether/when the journal syncs to a backend and its
  > contract — blocks `tasks.md` Phase 3 (the local-first storage itself can be
  > built without it).

## Open questions (resolved during implementation)

- <!-- none yet -->
