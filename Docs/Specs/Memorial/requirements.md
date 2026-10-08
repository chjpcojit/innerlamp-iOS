# Requirements — Memorial

Version: 1.3
Last updated: 2026-10-07
Status: implemented (build-verified, tests not run) — server API + Core Data offline cache; reminders and portrait stubbed
Feature folder: `InnerLamp/Presentation/Scenes/Memorial/`

> See `changelog.md` in this folder for the version history of this spec.

> Source of truth for layout and copy: the design prototype
> `Docs/InnerLamp icon consistency/InnerLamp Prototype.dc.html` — screens "Sổ giỗ chạp"
> (`isGio`) and "Thêm / sửa ngày giỗ" (`isGioEdit`), plus the "Sổ giỗ" link next to "Lịch âm" in
> Home's week strip.

## User Story

As a practitioner, I want to keep a book of my ancestors' and relatives' death anniversaries
(ngày giỗ), so that I never miss a giỗ and get reminded in time to prepare the offerings.

## Acceptance Criteria (EARS notation)

### Entry from Home

- WHEN the user taps the "Sổ giỗ" link beside "Lịch âm" in Home's week-strip header, THE SYSTEM
  SHALL open the Memorial list screen.

### List screen ("Sổ giỗ chạp")

- WHEN the list screen loads, THE SYSTEM SHALL read all saved entries, compute each entry's next
  anniversary date, and show them sorted by days remaining (soonest first), with the header
  subtitle "N người thân" (or "Chưa có ai" when empty).
- WHEN at least one entry exists, THE SYSTEM SHALL show a highlight card for the soonest entry
  with: the eyebrow ("GIỖ HÔM NAY" / "GIỖ NGÀY MAI" / "GIỖ SẮP TỚI · CÒN N NGÀY"), portrait,
  name, "relationship · ordinal" line (ordinal per the rule below), "Ngày giỗ" (the stored
  date), "Nhằm" (the next solar date, e.g. "Thứ Bảy, 15/11/2026") and "Nhắc nhở" (reminder
  summary or "Chưa bật"), then the section "THEO NGÀY GIỖ SẮP TỚI" listing every entry.
- WHEN a list row is rendered, THE SYSTEM SHALL show the portrait, name, "relationship · stored
  date", a days label ("Hôm nay" / "Ngày mai" / "còn N ngày", emphasised when ≤ 7 days) and a
  "Có nhắc" tag when a reminder is on.
- WHEN no entry exists, THE SYSTEM SHALL show the empty state ("Sổ giỗ còn trống" + its
  explanation) instead of the highlight card and list.
- WHEN the user taps "Thêm" in the nav bar or "Thêm người thân", THE SYSTEM SHALL open the
  add/edit screen in "add" mode.
- WHEN the user taps the highlight card or a list row, THE SYSTEM SHALL open the add/edit screen
  in "edit" mode for that entry.
- WHEN the user taps Back, THE SYSTEM SHALL return to Home.
- WHEN the add/edit screen returns after saving or deleting, THE SYSTEM SHALL refresh the list
  and show a transient confirmation banner (about 3.6 s) with the matching message (see below).

### Add / edit screen ("Thêm người thân" / "Sửa thông tin")

- WHEN the screen opens in add mode, THE SYSTEM SHALL prefill: relationship "Ông nội", calendar
  "Âm lịch", day 1, month 1, death year unknown, reminder on, lead "Trước 1 ngày", time "07:00",
  add-to-Reminders on, and title "Thêm người thân"; in edit mode it SHALL prefill the entry,
  title "Sửa thông tin", and show the delete button.
- WHEN the user fills the form, THE SYSTEM SHALL offer: portrait (tap to add), full name, a
  relationship chip group (Ông nội, Bà nội, Ông ngoại, Bà ngoại, Cha, Mẹ, Vợ / Chồng, Anh chị em,
  Con, Khác — single choice), a calendar toggle (Âm lịch / Dương lịch), day / month / death-year
  pickers, a note field, and the reminder card.
- WHEN the calendar is "Âm lịch", THE SYSTEM SHALL offer days 1–30 labelled "Mùng 1…Mùng 10" then
  numbers, and months "Tháng Giêng … Tháng Chạp"; WHEN it is "Dương lịch", days 1–31 and
  "Tháng 1…12". WHEN the user switches calendar, THE SYSTEM SHALL clamp the day to the new
  maximum.
- WHEN the death-year picker is shown, THE SYSTEM SHALL offer "Không rõ" plus the current year
  and the 96 years before it.
- WHEN day and month are set, THE SYSTEM SHALL show a live preview card: "Kỳ giỗ tới: <weekday,
  dd/MM/yyyy> · <days label>", and a second line — for a lunar date "Tức <d> tháng <m> âm lịch
  [· ordinal]. Tháng thiếu không có ngày 30 sẽ nhắc vào ngày 29."; for a solar date "Năm nay
  nhằm <d> tháng <m> âm lịch [· ordinal]".
- WHEN the death year is known, THE SYSTEM SHALL compute the ordinal of the next giỗ as
  (next anniversary year − death year): 1 → "Giỗ đầu", 2 → "Giỗ hết", n ≥ 3 → "Giỗ lần thứ n",
  anything < 1 → no ordinal; WHEN the year is unknown, THE SYSTEM SHALL show no ordinal.
- WHEN the reminder switch "Nhắc trước ngày giỗ" is on, THE SYSTEM SHALL show lead options
  (Đúng ngày, Trước 1 ngày, Trước 3 ngày, Trước 7 ngày), time options (06:00, 07:00, 12:00,
  19:00) and the "Thêm vào Lời nhắc (Reminders)" switch; WHEN it is off, THE SYSTEM SHALL hide
  them.
- WHEN the user taps Save ("Lưu vào sổ giỗ" / "Lưu thay đổi" / nav "Lưu") with an empty or
  whitespace-only name, THE SYSTEM SHALL show the inline error "Vui lòng nhập họ và tên", outline
  the field in the error colour and stay on the screen; the error SHALL clear on the next edit.
- WHEN the user taps Save with a valid name, THE SYSTEM SHALL trim the name, persist the entry
  (insert in add mode, update in edit mode), schedule/refresh its reminder if enabled, close the
  screen and report "Đã lưu vào sổ giỗ." — or, when reminder and add-to-Reminders are both on,
  "Đã lưu. Lời nhắc giỗ <relationship lowercased> đã được thêm vào ứng dụng Lời nhắc.".
- WHEN the user taps "Xóa khỏi sổ giỗ" (edit mode only), THE SYSTEM SHALL remove the entry and
  cancel its reminder, close the screen and report "Đã xóa <name or 'người thân'> khỏi sổ giỗ.".
- WHEN the user taps Back, THE SYSTEM SHALL close the screen without saving.

### Next-anniversary rule

- WHEN the entry is lunar, THE SYSTEM SHALL pick the first solar date on or after today among
  the entry's lunar day/month in lunar years (current − 1, current, current + 1); a 29-day lunar
  month has no day 30, so a day-30 entry falls on day 29 of that month (same rule as
  `ILLunarCalendar.matchesLunarDay`).
- WHEN the entry is solar, THE SYSTEM SHALL use the entry's day/month in the current year, or in
  next year if that date has passed; a day that does not exist in that month (e.g. 31 in a
  30-day month, 29 Feb in a non-leap year) SHALL fall on the month's last day.
- WHEN the next anniversary is today, THE SYSTEM SHALL report 0 days ("Hôm nay").

## Out of scope (this feature boundary, not backend work)

- Home's week-strip link itself — specified in `Docs/Specs/Home/` (v1.7) and built with Home.
- The family-tree ("Gia phả") prototype screen that can add an entry to the book — separate
  feature, not specified here.
- Notification delivery plumbing beyond scheduling this feature's own reminders.

## Pending (not yet implemented — see `tasks.md`)

- Reminder scheduling and the Reminders sync — the reminder fields are stored but nothing fires
  yet (`TD-Memorial-001`).

  > ⚠️ Not confirmed: whether "Nhắc nhở" is a local notification (UNUserNotificationCenter) only,
  > and whether "Thêm vào Lời nhắc (Reminders)" means Apple's Reminders app (EventKit, needs a
  > permission + Info.plist string) or an in-app list (the `Reminder` feature) — blocks the
  > reminder task in `tasks.md` Phase 2. Default assumed meanwhile: local notification, next
  > occurrence only, rescheduled on every list load (`AS-Memorial-002`).

- Portrait picker/storage — the portrait shows a placeholder avatar (`TD-Memorial-002`).
- Server sync: done 2026-10-07 — entries live on the server (`/v1/memorials`, per account, max 100) with a Core Data offline read cache (`AS-Memorial-005`, `AS-Memorial-006`). Offline create/edit/delete is not supported and shows an error.

- Visual QA (dark mode, long names, empty state, Dynamic Type) not yet done on device.

## Open questions (resolved during implementation)

- ~~Leap months~~ → regular month only; the leap month is skipped. Resolved 2026-10-03 (user accepted the default; recorded as `AS-Memorial-003`, still unvalidated).
- ~~Delete safety~~ → "Xóa khỏi sổ giỗ" deletes immediately, no dialog, as in the prototype. Resolved 2026-10-03 (`AS-Memorial-004`).
- ~~Portrait source/storage~~ → placeholder avatar for now; picker and storage deferred. Resolved 2026-10-03 as a deferral (`TD-Memorial-002`).
- ~~Storage~~ → Core Data only until an API exists (2026-10-03, `AS-Memorial-001`); superseded 2026-10-07 by server + offline cache (`AS-Memorial-006`).
