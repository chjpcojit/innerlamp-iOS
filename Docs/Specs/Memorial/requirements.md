# Requirements — Memorial

Version: 2.0
Last updated: 2026-10-14
Status: in-progress — list, form, server CRUD and offline read cache are built (build-verified, tests not run); product spec v1.0 alignment pending: leap month, year range, delete confirmation, reminders (stub), guest/offline edge cases, product vectors (`tasks.md` Phase 6–7)
Feature folder: `InnerLamp/Presentation/Scenes/Memorial/`
Product spec: innerlamp-be `docs/product/memorial/product.md` @ v1.0
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ 5f4ca56
Implements: BR-MEM-01, BR-MEM-02, BR-MEM-03, BR-MEM-04, BR-MEM-05, BR-MEM-06, BR-MEM-07, BR-MEM-08, BR-MEM-09, BR-MEM-10, BR-MEM-11, BR-MEM-12, FR-MEM-001..010, FR-MEM-011 (later), FR-MEM-012, FR-MEM-013, NFR-MEM-01, NFR-MEM-02, NFR-MEM-03

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the memorial book ("Sổ giỗ chạp"). Product behavior — the private
account-owned book, entry content and limits, date of death, leap months, next anniversary, days
left, which anniversary, reminders, permanent deletion — lives in the product spec and is **not**
restated here; this file only says how the iOS app implements those `BR-MEM-*` / `FR-MEM-*`. Written
prospectively (v1.0), built (v1.1–v1.3), rewritten retroactively in v2.0 to cite the product spec.
Product decisions previously recorded here or in `Docs/Assumptions/Memorial/AS-Memorial-001…006` are
now product IDs (see "Open questions (resolved)").

> Layout and copy source: the design prototype `InnerLamp Prototype.dc.html` (product spec §1.5),
> screens `gio` / `gioEmpty` (list) and `gioEdit` (form), plus the "Sổ giỗ" link beside "Lịch âm" in
> Home's week strip.

## User Story

As a signed-in practitioner, I want to keep a book of my deceased relatives' death anniversaries
(ngày giỗ) on my iPhone, so that I never miss a giỗ and am reminded in time to prepare the offerings.

## Constraints from the product spec

- **Client computes, server stores** (product §2.7, §3.6 row BR-MEM-05…10): the app computes the next
  anniversary, days left and which anniversary with its own port of the Vietnamese lunar calendar
  (`ILLunarCalendar`, UTC+7), and must pass the product vectors (BR-MEM-10, NFR-MEM-03).
- **Reminders are local** (§2.7, §3.6 row FR-MEM-008): the app schedules notifications on the device
  from the reminder settings stored on the server; no push.
- **iOS-only extra** (§3.6 row FR-MEM-009): the app may also add the anniversary to the iOS Reminders
  app; the server only stores the user's wish (`add_to_os_reminder`).
- **Offline read-only** (§3.6 row FR-MEM-010): the last loaded book is cached on the device (Core Data).
- Everything else behaves identically to the other platforms.

## Acceptance Criteria (EARS notation)

### Entry and access

1. WHEN a signed-in user taps the "Sổ giỗ" link beside "Lịch âm" in Home's week-strip header, THE SYSTEM SHALL push the memorial list screen and load the book via `GET /v1/memorials`. (FR-MEM-001)
2. WHEN a guest (opened Home through "guest preview", no access token) taps the "Sổ giỗ" link, THE SYSTEM SHALL ask the user to sign in and SHALL NOT show any memorial entry — neither from the server nor from the device cache. (FR-MEM-001, BR-MEM-01)
3. WHEN the user signs out, THE SYSTEM SHALL delete the memorial offline cache and cancel every memorial notification scheduled on the device, so a later guest or another account on the same device never sees or is reminded of this book. (BR-MEM-01, FR-MEM-008, NFR-MEM-02)

### List screen ("Sổ giỗ chạp")

4. WHEN the list loads, THE SYSTEM SHALL compute each entry's next anniversary, days left and ordinal per BR-MEM-05…09 (on-device "today", device time zone) and show the entries sorted by days left, soonest first, ties by name; the header subtitle shows "N người thân" (or "Chưa có ai" when empty). (FR-MEM-002, BR-MEM-05, BR-MEM-06, BR-MEM-07, BR-MEM-08)
5. WHEN at least one entry exists, THE SYSTEM SHALL show a highlight card for the soonest entry with the eyebrow ("GIỖ HÔM NAY" / "GIỖ NGÀY MAI" / "GIỖ SẮP TỚI · CÒN N NGÀY"), portrait, name, "relationship · ordinal label" (label per BR-MEM-09), "Ngày giỗ" (the date of death as entered, including the leap marker), "Nhằm" (the next solar date with weekday, e.g. "Thứ Hai, 23/11/2026") and "Nhắc nhở" (reminder summary or "Chưa bật"), then the section "THEO NGÀY GIỖ SẮP TỚI" listing every entry. (FR-MEM-002, BR-MEM-04, BR-MEM-09)
6. WHEN a list row is rendered, THE SYSTEM SHALL show the portrait, name, "relationship · date of death as entered", the days-left label of BR-MEM-08 (emphasised when BR-MEM-08 says so) and a "Có nhắc" tag when the reminder is on. (FR-MEM-002, FR-MEM-007, BR-MEM-08)
7. WHEN the book is empty, THE SYSTEM SHALL show the empty state (`gioEmpty`: "Sổ giỗ còn trống", its explanation and steps) instead of the highlight card and list. (FR-MEM-002)
8. WHEN the user taps the sticky "Thêm người thân" button, THE SYSTEM SHALL open the form in add mode; WHEN the user taps the highlight card or a row, THE SYSTEM SHALL open the form in edit mode for that entry (the entity is handed over, no extra load). (platform)
9. WHEN the user taps Back, THE SYSTEM SHALL return to Home. (platform)
10. WHEN the form closes after a save or delete, THE SYSTEM SHALL reload the list and show a transient confirmation toast (about 3.6 s) with the form's message. (FR-MEM-003, FR-MEM-005)
11. WHEN loading the book fails for any reason other than being offline or signed out, THE SYSTEM SHALL show an error state with a retry, not the empty state. (FR-MEM-002)

    > ⚠️ Not confirmed (product): when the server is reachable but fails (e.g. 5xx), should the apps fall back to the offline copy like FR-MEM-010, or show an error? — blocks criterion 11 and `tasks.md` Phase 6 "load-failure state"; hand back to ba-writer in innerlamp-be.

### Add / edit form ("Thêm người thân" / "Sửa thông tin")

12. WHEN the form opens in add mode, THE SYSTEM SHALL prefill the new-entry defaults of FR-MEM-003 (including "add to the Reminders app" on) with title "Thêm người thân"; in edit mode it SHALL prefill the entry, title "Sửa thông tin", and show "Xóa khỏi sổ giỗ". (FR-MEM-003, FR-MEM-004, FR-MEM-009)
13. WHEN the user fills the form, THE SYSTEM SHALL offer: portrait (placeholder, see criterion 33), full name, a single-choice relationship chip group with the ten BR-MEM-02 values in prototype order, a calendar toggle (Âm lịch / Dương lịch), day / month / death-year pull-down menus, a leap-month switch shown only for "Âm lịch", a note field, and the reminder card. (FR-MEM-003, BR-MEM-02, BR-MEM-03, BR-MEM-04)

    > ⚠️ Not confirmed (product): copy and placement of the leap-month choice in the form and of the leap marker in the list/highlight ("10/6 nhuận/2025" is the only example) — the prototype has no leap UI — blocks criteria 5, 13 and the Phase 6 leap task's copy; hand back to ba-writer in innerlamp-be.

14. WHEN the calendar is "Âm lịch", THE SYSTEM SHALL offer days 1–30 labelled "Mùng 1…Mùng 10" then numbers and months "Tháng Giêng … Tháng Chạp"; WHEN it is "Dương lịch", days 1 to the month's length (February 29) and "Tháng 1…12"; WHEN the calendar or month changes, THE SYSTEM SHALL clamp the day to the new maximum. (BR-MEM-03)
15. WHEN the death-year menu is shown, THE SYSTEM SHALL offer "Không rõ" plus every year from the current year down to 1900. (BR-MEM-03)
16. WHEN day and month are set, THE SYSTEM SHALL update the preview card on every change: "Kỳ giỗ tới: <weekday, dd/MM/yyyy> · <days label>", and a second line — lunar: "Tức <d> tháng <m> âm lịch [· ordinal label]. Tháng thiếu không có ngày 30 sẽ nhắc vào ngày 29."; solar: "Năm nay nhằm <d> tháng <m> âm lịch [· ordinal label]". (FR-MEM-006, BR-MEM-05…09, NFR-MEM-01)
17. WHEN the user taps Save with a name that is empty after trimming, THE SYSTEM SHALL show the FR-MEM-012 message under the name field, outline the field in the error colour and stay on the form; the message SHALL clear on the next keystroke. (FR-MEM-012, BR-MEM-02)
18. WHEN the user taps Save with a name longer than 100 characters after trimming, or a note longer than 1000 characters, THE SYSTEM SHALL stay on the form, send nothing, and show a field-specific "too long" message. (FR-MEM-012, FR-MEM-013, BR-MEM-02)

    > ⚠️ Not confirmed (product): exact copy of the "name too long", "note too long", "date not valid", "book cannot be loaded offline" and delete-confirmation texts — neither the product spec nor the prototype gives them — blocks the copy of criteria 18, 19, 23, 30; hand back to ba-writer in innerlamp-be.

19. WHEN the user taps Save with a death year and a date that does not exist in the chosen calendar (e.g. solar 29/2/2025, lunar 30 in a 29-day month of that lunar year, a leap month that lunar year does not have) or that is after today, THE SYSTEM SHALL stay on the form, send nothing, and say the date is not valid — the conversion used here SHALL be strict (no day-30 → 29 fallback). (FR-MEM-003, BR-MEM-03, BR-MEM-04, BR-MEM-10)
20. WHEN the user taps Save with valid content, THE SYSTEM SHALL trim the name, send the whole entry (`POST /v1/memorials` in add mode, `PUT /v1/memorials/{id}` in edit mode, see design "Server sync"), re-plan its reminder (criterion 26), close the form and report "Đã lưu vào sổ giỗ." — or, when the reminder and "add to the Reminders app" are both on, the FR-MEM-009 message with the relationship in lower case. (FR-MEM-003, FR-MEM-004, FR-MEM-009, BR-MEM-02)
21. WHEN a blank note is saved, THE SYSTEM SHALL send it as no note; WHEN an entry with a note is opened, THE SYSTEM SHALL show the note. (FR-MEM-013)
22. WHEN the user taps Back on the form, THE SYSTEM SHALL close it without saving and the entry SHALL stay unchanged. (FR-MEM-004)
23. WHEN a save in edit mode fails because the entry no longer exists on the server, THE SYSTEM SHALL tell the user, close the form, and reload the list so the entry is no longer shown. (FR-MEM-004, BR-MEM-01)

### Delete

24. WHEN the user taps "Xóa khỏi sổ giỗ" (edit mode only), THE SYSTEM SHALL ask for confirmation in an action sheet with a destructive "Xóa" and a "Hủy"; WHEN the user cancels, nothing changes. (FR-MEM-005, BR-MEM-12)
25. WHEN the user confirms, THE SYSTEM SHALL call `DELETE /v1/memorials/{id}` (a 404 counts as already deleted), cancel the entry's notification and Reminders item, close the form and report "Đã xóa <name or 'người thân'> khỏi sổ giỗ.". (FR-MEM-005, BR-MEM-12, FR-MEM-008)

### Reminders

26. WHEN the reminder switch "Nhắc trước ngày giỗ" is on, THE SYSTEM SHALL show exactly the BR-MEM-11 lead choices (Đúng ngày, Trước 1 / 3 / 7 ngày), time choices (06:00, 07:00, 12:00, 19:00) and the "Thêm vào Lời nhắc (Reminders)" switch; WHEN it is off, THE SYSTEM SHALL hide them and save no reminder. (FR-MEM-007, FR-MEM-009, BR-MEM-11)

    > ⚠️ Not confirmed (product): what the form shows and saves when an entry from the server carries a lead or time outside the BR-MEM-11 choices (the contract accepts 0–30 days and any `HH:mm`) — blocks criterion 26 for such entries; hand back to ba-writer in innerlamp-be.

27. WHEN an entry's reminder is saved, THE SYSTEM SHALL send `reminder.timezone` = the device's IANA time zone. (BR-MEM-11)
28. WHEN the list loads (from the server or the cache) or an entry is saved, THE SYSTEM SHALL replace the device's scheduled memorial notifications with one local notification per entry whose reminder is on, at the BR-MEM-11 moment before that entry's next anniversary (device local time), and remove the notifications of entries that are gone or have the reminder off. (FR-MEM-008, BR-MEM-05, BR-MEM-11)
29. WHEN the first reminder is about to be scheduled and notification permission was never asked, THE SYSTEM SHALL ask for it. (FR-MEM-008)

    > ⚠️ Not confirmed (product): what the user sees when notification permission is denied (silent, an inline hint on the reminder card, or a prompt to open Settings) — blocks the permission-denied branch of criterion 29; hand back to ba-writer in innerlamp-be.

    > ⚠️ Not confirmed (product): a delete or reminder-off made on another device only stops this device's notification the next time this device loads the book (FR-MEM-008 scenario 2 names that moment for turning a reminder on); FR-MEM-005 says "no reminder fires afterwards" — is the next-load refresh acceptable? — blocks nothing built today, affects criterion 28; hand back to ba-writer in innerlamp-be.

30. WHEN an entry is saved with the reminder on and "Thêm vào Lời nhắc" on, THE SYSTEM SHALL add the anniversary to the iOS Reminders app (EventKit), asking for Reminders access first. (FR-MEM-009)

    > ⚠️ Not confirmed (product): for FR-MEM-009 — (a) what happens to the Reminders item when the entry is edited, its reminder turned off, or deleted; (b) one item per next anniversary or one yearly item; (c) the flag is stored on the account, so a second iPhone (same iCloud Reminders) would add a duplicate — should only the device that saved it add it; (d) what the user sees when Reminders access is denied — blocks `tasks.md` Phase 7 Reminders-app tasks; hand back to ba-writer in innerlamp-be.

### Offline

31. WHEN the app cannot reach the server while loading the book and this account's cache holds entries, THE SYSTEM SHALL show the cached book with next anniversaries computed for today. (FR-MEM-010, BR-MEM-05)
32. WHEN the app cannot reach the server while loading and there is no cache for this account, THE SYSTEM SHALL say the book cannot be loaded without a connection (not the empty state); WHEN the user tries to save or delete offline, THE SYSTEM SHALL show "Không có kết nối mạng. Vui lòng thử lại." and change nothing. (FR-MEM-010)

### Portrait (later)

33. WHEN an entry has no portrait, THE SYSTEM SHALL show the relative's initial in the avatar; picking, converting (HEIC → JPEG), uploading and showing a portrait is deferred until the backend photo route exists. (FR-MEM-011)

### Calendar correctness, privacy, responsiveness

34. WHEN the unit tests run, THE SYSTEM SHALL pass every case of the product vector files `rules/next-anniversary.json`, `rules/anniversary-ordinal.json` and `rules/death-date-conversion.json` against `ILMemorialUseCase` / `ILMemorialFormatter` / `ILLunarCalendar`. (NFR-MEM-03, BR-MEM-10, BR-MEM-03…09)
35. WHEN the memorial feature logs (network logger, Sentry, analytics), THE SYSTEM SHALL NOT include names, notes or photos — only method, path (numeric id), status and timing. (NFR-MEM-02)
36. WHEN the book holds 100 entries on a 4G connection, THE SYSTEM SHALL show the list within 2 s of opening it. (NFR-MEM-01)

## Error → UI mapping

Operations are cited from the contract; schemas and the full error list stay in `openapi.yaml`.

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/memorials` | offline / timeout | cached book (criterion 31) or "cannot load offline" (criterion 32) |
| `GET /v1/memorials` | 401 (guest or expired session) | sign-in prompt (criterion 2); cache never shown |
| `GET /v1/memorials` | other failure | error state with retry (criterion 11, ⚠️ product) |
| `POST` / `PUT /v1/memorials[/{id}]` | offline / timeout | alert "Không có kết nối mạng. Vui lòng thử lại.", stays on the form |
| `POST /v1/memorials` | 409 `MEMORIAL_LIMIT_REACHED` | alert "Sổ giỗ đã đủ 100 người. Hãy xóa bớt để thêm mới.", stays on the form |
| `POST` / `PUT` | 400 `VALIDATION_ERROR` | alert "Thông tin chưa hợp lệ…" (only reachable if local checks of criteria 18–19 miss a case), stays on the form |
| `PUT /v1/memorials/{id}` | 404 `MEMORIAL_NOT_FOUND` | alert, form closes, list reloads (criterion 23) |
| `POST` / `PUT` / `DELETE` | 401 | alert "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại." |
| `DELETE /v1/memorials/{id}` | 404 `MEMORIAL_NOT_FOUND` | treated as success (criterion 25) |
| any | other | alert with the operation's "Vui lòng thử lại." message |

## Out of scope (this feature boundary, not tracked here)

- Home's week-strip link itself — `Docs/Specs/Home/` (v1.7).
- The family-tree ("Gia phả") screens and creating entries from the tree — `genealogy` product spec; the "Xem gia phả" button only navigates there.
- Sharing a book, search, export, soft delete (product §1.2).
- Server push reminders (product §2.7).

## Pending (not yet implemented — see `tasks.md`)

Criteria the shipped code does **not** meet yet (drift against product spec v1.0):

- Criterion 2 — a guest sees the empty book (the 401 is swallowed) instead of a sign-in prompt (FR-MEM-001).
- Criterion 3 — sign-out keeps the Core Data cache and it is not keyed by account; offline, a guest or another account would see it (BR-MEM-01, NFR-MEM-02).
- Criteria 5, 13 — no leap-month choice; the leap marker is always sent as `false` and dropped on load (BR-MEM-04). Was `AS-Memorial-003`.
- Criterion 11 — any load failure shows the empty state.
- Criterion 15 — the year menu offers the current year and the 96 before it, not back to 1900 (BR-MEM-03).
- Criterion 18 — no client length limits; the server's 400 shows one generic message.
- Criterion 19 — a lunar day 30 in a 29-day month with a known year is silently saved as day 29 (`lunarToSolar` clamps), and a date after today is only caught by the server (generic message) (BR-MEM-03).
- Criterion 23 — a 404 on save leaves the user on the form and the list still shows the entry until the next load.
- Criteria 24–25 — delete happens immediately, no confirmation (BR-MEM-12). Was `AS-Memorial-004`.
- Criterion 27 — `reminder.timezone` is not sent (server default `Asia/Ho_Chi_Minh`).
- Criteria 28–30 — reminders and the Reminders app are one-line stubs (`TD-Memorial-001`).
- Criterion 32 — never-loaded + offline shows the empty state.
- Criterion 33 — portrait upload (backend photo route not built; `TD-Memorial-002`, backend `TD-001`).
- Criterion 34 — vectors are not run; known mismatches before running: ordinal 0 is collapsed to `nil` (vector expects `0`), strict day-30 / leap conversion (criterion 19), no leap input.
- Criterion 36 — not measured.
- Visual QA on device (dark mode, long names, empty state, Dynamic Type).

## Open questions (resolved)

- ~~Leap months~~ → product BR-MEM-04 / BR-MEM-05 (a death may be in a leap month; the anniversary is always in the regular month). Supersedes the 2026-10-03 "skip leap months" default (`AS-Memorial-003`). Resolved 2026-10-14 by product spec v1.0.
- ~~Delete safety~~ → product BR-MEM-12 (ask for confirmation). Supersedes the 2026-10-03 "delete immediately" default (`AS-Memorial-004`). Resolved 2026-10-14 by product spec v1.0.
- ~~Reminder mechanism: local notification vs Apple Reminders vs in-app list; reschedule policy~~ → product FR-MEM-008 (local notifications on every signed-in app device), FR-MEM-009 (iOS Reminders app, iOS only), BR-MEM-11 (fixed choices, device local time, one per next anniversary). The iOS mechanism (UNUserNotificationCenter + EventKit, refresh on load/save) is in `design.md`. Supersedes `AS-Memorial-002`. Resolved 2026-10-14 by product spec v1.0; the sub-questions still open are the ⚠️ items under criteria 29–30.
- ~~Storage / source of truth / offline~~ → product BR-MEM-01 + FR-MEM-010 (account-owned book, offline read-only in the apps). Supersedes `AS-Memorial-001` (already invalidated) and `AS-Memorial-006`. Resolved 2026-10-14 by product spec v1.0.
- ~~Date-of-death mapping to the API~~ → product BR-MEM-03 / BR-MEM-04 / BR-MEM-10 for the rules; the wire mapping is in `design.md` "Server sync". Supersedes `AS-Memorial-005`. Resolved 2026-10-14.
- ~~Year range~~ → product BR-MEM-03 (1900 → current year). Replaces the prototype's 96-year menu. Resolved 2026-10-14.
- ~~Portrait source/storage~~ → product FR-MEM-011 (planned; JPEG/PNG/WebP ≤ 5 MB, apps convert HEIC to JPEG); deferred until the backend photo route exists (`TD-Memorial-002`). Resolved 2026-10-14.
- ~~API contract~~ → `/v1/memorials` (innerlamp-be `openapi.yaml`). Resolved 2026-10-07.
