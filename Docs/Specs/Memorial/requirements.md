# Requirements — Memorial

Version: 3.1
Last updated: 2026-10-14
Status: in-progress — list, form, server CRUD and offline read cache are built (build-verified, tests not run); product spec v2.1 alignment pending: remove the local-reminder stubs and the Reminders-app option, push via FCM, account time zone, leap month, year range, delete confirmation, offline / server-error / sign-out edge cases, product vectors (`tasks.md` Phase 6–8)
Feature folder: `InnerLamp/Presentation/Scenes/Memorial/`
Product spec: innerlamp-be `docs/product/memorial/product.md` @ v2.1
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ bf23f8b (memorial operations unchanged since 5f4ca56; no notification-list, push-token or account time-zone operations yet)
Architecture: ADR-0001 (in-app notification list on every platform, push via FCM on the apps), ADR-0002 (the backend computes and sends memorial reminders) — both Accepted
Implements: BR-MEM-01, BR-MEM-02, BR-MEM-03, BR-MEM-04, BR-MEM-05, BR-MEM-06, BR-MEM-07, BR-MEM-08, BR-MEM-09, BR-MEM-10, BR-MEM-11, BR-MEM-12, FR-MEM-001..008, FR-MEM-010, FR-MEM-011 (later), FR-MEM-012, FR-MEM-013, NFR-MEM-01, NFR-MEM-02, NFR-MEM-03
Not on iOS: BR-MEM-13 and NFR-MEM-04 (Backend only); FR-MEM-009 (Removed in product v2.0)
Depends on: `Docs/Specs/Notifications/` (the in-app notification list — a separate cross-cutting feature, ADR-0001; today mock data only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the memorial book ("Sổ giỗ chạp"). Product behavior — the private
account-owned book, entry content and limits, date of death, leap months, next anniversary, days
left, which anniversary, reminder settings and delivery, permanent deletion, offline reading — lives
in the product spec and is **not** restated here; this file only says how the iOS app implements those
`BR-MEM-*` / `FR-MEM-*`. Written prospectively (v1.0), built (v1.1–v1.3), rewritten retroactively in
v2.0 to cite the product spec, moved to server-sent reminders in v3.0.

> Layout source: the design prototype `InnerLamp Prototype.dc.html` (product spec §1.5), screens `gio`
> / `gioEmpty` (list) and `gioEdit` (form), plus the "Sổ giỗ" link beside "Lịch âm" in Home's week
> strip. Copy source: product spec §3.1.1 (the prototype's copy where §3.1.1 is silent).

## User Story

As a signed-in practitioner, I want to keep a book of my deceased relatives' death anniversaries
(ngày giỗ) on my iPhone, so that I never miss a giỗ and am reminded in time to prepare the offerings.

## Constraints from the product spec

- **The server sends reminders** (product §2.7, ADR-0002): the app never schedules a reminder on the
  device. It edits the reminder settings, reports the device's time zone as the account time zone
  (BR-MEM-11), and receives reminders as FCM push notifications and in the notification list
  (FR-MEM-008, §3.6 row FR-MEM-008, ADR-0001).
- **Clients compute for display** (§3.6 row BR-MEM-05…10): the app computes the next anniversary, days
  left and which anniversary with its own port of the Vietnamese lunar calendar (`ILLunarCalendar`,
  UTC+7) and must pass the client product vectors (BR-MEM-10, NFR-MEM-03, product §4.3).
- **The notification list is another feature** (product §1.2): this spec only covers what the memorial
  book needs from it — a memorial reminder opens its entry. The list screen is `Docs/Specs/Notifications/`.
- **Offline read-only** (§3.6 row FR-MEM-010): the last loaded book of the signed-in account is kept on
  the device (Core Data) and removed on sign-out.
- **No device reminders app** (FR-MEM-009 removed in product v2.0).
- **Account-wide notification switch** (FR-MEM-008 @ v2.1): turns off push only, on every device of the
  account; memorial reminders still reach the notification list. The switch is enforced by the server
  and its UI is not part of this feature, so the memorial screens behave the same with it on or off.
- Everything else behaves identically to the other platforms.

## Acceptance Criteria (EARS notation)

### Entry and access

1. WHEN a signed-in user taps the "Sổ giỗ" link beside "Lịch âm" in Home's week-strip header, THE SYSTEM SHALL push the memorial list screen and load the book via `GET /v1/memorials`. (FR-MEM-001)
2. WHEN a guest (opened Home through "guest preview", no access token) taps the "Sổ giỗ" link, THE SYSTEM SHALL ask the user to sign in and SHALL NOT show any memorial entry — neither from the server nor from the offline copy. (FR-MEM-001, BR-MEM-01)
3. WHEN the user signs out, or the session ends because it could not be refreshed, THE SYSTEM SHALL delete the memorial offline copy from the device. (FR-MEM-010, BR-MEM-01, NFR-MEM-02)
4. WHEN the user signs out, THE SYSTEM SHALL stop push to this device — remove its push registration from the server (criterion 30) and invalidate its FCM token — and SHALL remove InnerLamp notifications already shown in Notification Center. (FR-MEM-008, NFR-MEM-02)

### List screen ("Sổ giỗ chạp")

5. WHEN the list loads, THE SYSTEM SHALL compute each entry's next anniversary, days left and ordinal per BR-MEM-05…09 (on-device "today", device time zone) and show the entries sorted by days left, soonest first, ties by name; the header subtitle shows "N người thân" (or "Chưa có ai" when empty). (FR-MEM-002, BR-MEM-05, BR-MEM-06, BR-MEM-07, BR-MEM-08)
6. WHEN at least one entry exists, THE SYSTEM SHALL show a highlight card for the soonest entry with the eyebrow ("GIỖ HÔM NAY" / "GIỖ NGÀY MAI" / "GIỖ SẮP TỚI · CÒN N NGÀY"), portrait, name, "relationship · ordinal label" (label per BR-MEM-09), "Ngày giỗ" (the date of death as entered, a leap date as "10/6 nhuận"), "Nhằm" (the next solar date with weekday, e.g. "Thứ Hai, 23/11/2026") and "Nhắc nhở" (reminder summary or "Chưa bật"), then the section "THEO NGÀY GIỖ SẮP TỚI" listing every entry. (FR-MEM-002, BR-MEM-04, BR-MEM-09)
7. WHEN a list row is rendered, THE SYSTEM SHALL show the portrait, name, "relationship · date of death as entered", the days-left label of BR-MEM-08 (emphasised when BR-MEM-08 says so) and a "Có nhắc" tag when the entry's reminder is on — whether or not this device allows notifications. (FR-MEM-002, FR-MEM-007, BR-MEM-08)
8. WHEN the book is empty, THE SYSTEM SHALL show the empty state (`gioEmpty`: "Sổ giỗ còn trống", its explanation and steps) instead of the highlight card and list, with no "Lấy từ gia phả" option; WHEN the book is not empty, THE SYSTEM SHALL show no "Xem gia phả" button under the list. (FR-MEM-002)
9. WHEN the user taps the sticky "Thêm người thân" button, THE SYSTEM SHALL open the form in add mode; WHEN the user taps the highlight card or a row, THE SYSTEM SHALL open the form in edit mode for that entry (the entity is handed over, no extra load). (platform)
10. WHEN the user taps Back, THE SYSTEM SHALL return to Home. (platform)
11. WHEN the form closes after a save or delete, THE SYSTEM SHALL reload the list and show a transient confirmation toast (about 3.6 s) with the form's message. (FR-MEM-003, FR-MEM-005)

### Add / edit form ("Thêm người thân" / "Sửa thông tin")

12. WHEN the form opens in add mode, THE SYSTEM SHALL prefill the new-entry defaults of FR-MEM-003 with title "Thêm người thân"; in edit mode it SHALL prefill the entry, title "Sửa thông tin", and show "Xóa khỏi sổ giỗ". (FR-MEM-003, FR-MEM-004)
13. WHEN the user fills the form, THE SYSTEM SHALL offer: portrait (placeholder, see criterion 40), full name, a single-choice relationship chip group with the ten BR-MEM-02 values in prototype order, a calendar toggle (Âm lịch / Dương lịch), day / month / death-year pull-down menus, a "Tháng nhuận" switch shown only for "Âm lịch", a note field, and the reminder card. (FR-MEM-003, BR-MEM-02, BR-MEM-03, BR-MEM-04)
14. WHEN the calendar is "Âm lịch", THE SYSTEM SHALL offer days 1–30 labelled "Mùng 1…Mùng 10" then numbers and months "Tháng Giêng … Tháng Chạp"; WHEN it is "Dương lịch", days 1 to the month's length (February 29) and "Tháng 1…12"; WHEN the calendar or month changes, THE SYSTEM SHALL clamp the day to the new maximum. (BR-MEM-03)
15. WHEN the death-year menu is shown, THE SYSTEM SHALL offer "Không rõ" plus every year from the current year down to 1900. (BR-MEM-03)
16. WHEN day and month are set, THE SYSTEM SHALL update the preview card on every change: "Kỳ giỗ tới: <weekday, dd/MM/yyyy> · <days label>", and a second line — lunar: "Tức <d> tháng <m> âm lịch [· ordinal label]. Tháng thiếu không có ngày 30 sẽ nhắc vào ngày 29."; solar: "Năm nay nhằm <d> tháng <m> âm lịch [· ordinal label]". (FR-MEM-006, BR-MEM-05…09, NFR-MEM-01)
17. WHEN the user taps Save with a name that is empty after trimming, THE SYSTEM SHALL show "Vui lòng nhập họ và tên" under the name field, outline the field in the error colour and stay on the form; the message SHALL clear on the next keystroke. (FR-MEM-012, BR-MEM-02)
18. WHEN the user taps Save with a name longer than 100 characters after trimming, or a note longer than 1000 characters, THE SYSTEM SHALL stay on the form, send nothing, and show the §3.1.1 message under that field ("Họ và tên tối đa 100 ký tự" / "Ghi chú tối đa 1000 ký tự"). (FR-MEM-012, FR-MEM-013, BR-MEM-02)
19. WHEN the user taps Save with a death year and a date that is not valid, THE SYSTEM SHALL stay on the form, send nothing, and show the §3.1.1 message for the case — the date does not exist in the chosen calendar (e.g. solar 29/2/2025, lunar 30 in a 29-day month of that lunar year): "Ngày này không có trong lịch. Vui lòng kiểm tra lại."; the lunar year has no such leap month: "Năm {năm} không có tháng {tháng} nhuận."; a year before 1900: "Năm mất phải từ 1900 trở về sau."; a date after today: "Ngày mất không thể sau hôm nay." The conversion used here SHALL be strict (no day-30 → 29 fallback). (FR-MEM-003, BR-MEM-03, BR-MEM-04, BR-MEM-10)
20. WHEN the user taps Save with valid content, THE SYSTEM SHALL trim the name, send the whole entry (`POST /v1/memorials` in add mode, `PUT /v1/memorials/{id}` in edit mode, see design "Server sync"), close the form and report "Đã lưu vào sổ giỗ.". (FR-MEM-003, FR-MEM-004, BR-MEM-02)
21. WHEN a blank note is saved, THE SYSTEM SHALL send it as no note; WHEN an entry with a note is opened, THE SYSTEM SHALL show the note. (FR-MEM-013)
22. WHEN the user taps Back on the form, THE SYSTEM SHALL close it without saving and the entry SHALL stay unchanged. (FR-MEM-004)
23. WHEN a save in edit mode fails because the entry no longer exists on the server, THE SYSTEM SHALL show "Mục này không còn trong sổ giỗ.", close the form, remove the entry from the offline copy and reload the list so it is no longer shown. (FR-MEM-004, BR-MEM-01)

### Delete

24. WHEN the user taps "Xóa khỏi sổ giỗ" (edit mode only), THE SYSTEM SHALL ask for confirmation in an action sheet titled "Xóa {tên} khỏi sổ giỗ?" with the message "Không thể khôi phục sau khi xóa.", a destructive "Xóa" and a "Hủy"; WHEN the user cancels, nothing changes. (FR-MEM-005, BR-MEM-12)
25. WHEN the user confirms, THE SYSTEM SHALL call `DELETE /v1/memorials/{id}`, remove the entry from the offline copy, close the form and report "Đã xóa {tên} khỏi sổ giỗ." ("người thân" when the name is empty); stopping the entry's reminder is the server's job (ADR-0002), the app cancels nothing on the device. (FR-MEM-005, BR-MEM-12, FR-MEM-008)
26. WHEN the delete fails because the entry no longer exists on the server, THE SYSTEM SHALL treat it as removed — remove it from the offline copy, close the form, reload the list — and show "Mục này không còn trong sổ giỗ." instead of the deleted message. (FR-MEM-005)

### Reminder settings

27. WHEN the reminder switch "Nhắc trước ngày giỗ" is on, THE SYSTEM SHALL show exactly the BR-MEM-11 lead choices (Đúng ngày, Trước 1 / 3 / 7 ngày) and time choices (06:00, 07:00, 12:00, 19:00); WHEN it is off, THE SYSTEM SHALL hide them and save no reminder. There is no "Thêm vào Lời nhắc (Reminders)" option. (FR-MEM-007, BR-MEM-11)
28. WHEN an entry from the server carries a lead or time outside the BR-MEM-11 choices, THE SYSTEM SHALL select the nearest choice in the form; going back without saving SHALL leave the stored value unchanged, and saving SHALL send the selected choice. (FR-MEM-007, BR-MEM-11)

    > ⚠️ Not confirmed (product): which choice is "nearest" on a tie or outside the range — lead 2 (1 or 3), lead 5 (3 or 7), a time half-way between two choices (e.g. 09:30: 07:00 or 12:00), a time before 06:00 or after 19:00 (wrap round midnight or not) — and whether the list's "Nhắc nhở" summary shows the stored value or the nearest choice — blocks the mapping in `tasks.md` Phase 6 "Nearest reminder choice"; hand back to ba-writer in innerlamp-be.

29. WHEN the reminder card is shown with the reminder on and this device has denied notifications for InnerLamp, THE SYSTEM SHALL show the hint "Bạn sẽ chỉ thấy lời nhắc trong mục Thông báo. Mở Cài đặt để bật thông báo đẩy." with a "Mở Cài đặt" button that opens InnerLamp's notification settings; the reminder setting itself is kept and saved as usual. (FR-MEM-008, FR-MEM-007)

### Push notifications and account time zone

30. WHEN the user signs in, WHEN the app starts with a stored session, and WHENEVER the FCM registration token changes while signed in, THE SYSTEM SHALL register this device's FCM token with the server for the signed-in account. (FR-MEM-008, ADR-0001)

    > ⚠️ Not confirmed (contract): the operations to register and remove a device's push token (path, fields, link to the login `device`) are not in `openapi.yaml` (product Appendix B item 8) — blocks criteria 4 and 30 and `tasks.md` Phase 8; hand-off to the backend.

31. WHEN notification permission was never asked on this device and either the user saves an entry with the reminder on or the book loads with at least one entry whose reminder is on, THE SYSTEM SHALL ask for notification permission (alert, sound, badge) once. (platform, FR-MEM-008)
32. WHEN a memorial push arrives, THE SYSTEM SHALL show it with the text the server sent — the relationship only, never the relative's name (§3.1.1) — and SHALL NOT add the name, note or photo on the device; while the app is in the foreground it SHALL still show the banner. (FR-MEM-008, NFR-MEM-02)
33. WHEN the user opens a memorial push, or chooses a memorial reminder in the notification list, THE SYSTEM SHALL open that entry: Home → memorial book → the form in edit mode, loaded with `GET /v1/memorials/{id}`; WHEN the entry no longer exists, THE SYSTEM SHALL show the book and "Mục này không còn trong sổ giỗ."; WHEN no one is signed in, THE SYSTEM SHALL ask the user to sign in and show nothing. (FR-MEM-008, FR-MEM-004, BR-MEM-01)

    > ⚠️ Not confirmed (contract): how a memorial reminder identifies its entry in the push payload and in a notification-list item (type and memorial id keys) — product Appendix B item 7 — blocks criterion 33 and the deep-link tasks of `tasks.md` Phase 8; hand-off to the backend.

34. WHEN the user signs in, WHEN the app becomes active with a session, and WHEN the system time zone changes while signed in, THE SYSTEM SHALL report the device's IANA time zone (`TimeZone.current.identifier`) as the account time zone. (BR-MEM-11, ADR-0002)

    > ⚠️ Not confirmed (contract): the operation that sets the account time zone (product Appendix B item 3) is not in `openapi.yaml` — blocks criterion 34 and `tasks.md` Phase 8 "Account time zone"; hand-off to the backend.

35. WHEN an entry is saved, THE SYSTEM SHALL NOT send a per-entry time zone (`reminder.timezone`) or the Reminders-app wish (`add_to_os_reminder`). (BR-MEM-11, FR-MEM-009 removed)

### Offline and server failure

36. WHEN loading the book fails for any reason other than a missing or expired session — no connection, timeout or a server error (5xx) — and the offline copy of the signed-in account holds entries, THE SYSTEM SHALL show that copy with next anniversaries computed for today and the line "Đang hiện sổ giỗ đã tải lần trước. Không kết nối được máy chủ.". (FR-MEM-010, BR-MEM-05)
37. WHEN loading fails as in criterion 36 and there is no offline copy for the signed-in account, THE SYSTEM SHALL show "Chưa tải được sổ giỗ. Vui lòng kết nối mạng và thử lại." with a retry, not the empty state. (FR-MEM-010)
38. WHEN the user saves or deletes while offline, THE SYSTEM SHALL show "Cần kết nối mạng để thay đổi sổ giỗ." and change nothing; WHEN a save fails on a server error, THE SYSTEM SHALL show "Chưa lưu được. Vui lòng thử lại." and stay on the form. (FR-MEM-010, FR-MEM-003)
39. WHEN the offline copy is read, THE SYSTEM SHALL use it only if it was stored for the account that is signed in now. (FR-MEM-010, BR-MEM-01)

### Portrait (later)

40. WHEN an entry has no portrait, THE SYSTEM SHALL show the relative's initial in the avatar; picking, converting (HEIC → JPEG), uploading and showing a portrait is deferred until the backend photo route exists. (FR-MEM-011)

### Calendar correctness, privacy, responsiveness

41. WHEN the unit tests run, THE SYSTEM SHALL pass every case of the client product vector files `rules/next-anniversary.json`, `rules/anniversary-ordinal.json` and `rules/death-date-conversion.json` against `ILMemorialUseCase` / `ILMemorialFormatter` / `ILLunarCalendar`; `rules/reminder-moment.json` is run by the backend only (product §4.3). (NFR-MEM-03, BR-MEM-10, BR-MEM-03…09)
42. WHEN the memorial feature or push handling logs (network logger, Sentry, analytics), THE SYSTEM SHALL NOT include names, notes, photos, push tokens or push payload text — only method, path (numeric id), status and timing. (NFR-MEM-02)
43. WHEN the book holds 100 entries on a 4G connection, THE SYSTEM SHALL show the list within 2 s of opening it. (NFR-MEM-01)

## Error → UI mapping

Operations are cited from the contract; schemas and the full error list stay in `openapi.yaml`. Copy is
product §3.1.1.

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/memorials` | offline / timeout / 5xx / other non-401 | offline copy + line (criterion 36) or "Chưa tải được sổ giỗ…" with retry (criterion 37) |
| `GET /v1/memorials` | 401 (guest or expired session) | sign-in prompt (criterion 2); offline copy never shown |
| `GET /v1/memorials/{id}` (open from a reminder) | 404 `MEMORIAL_NOT_FOUND` | the book + "Mục này không còn trong sổ giỗ." (criterion 33) |
| `GET /v1/memorials/{id}` | offline / 5xx | the book (offline copy rules of criteria 36–37); the entry opens from the offline copy when it is there |
| `POST` / `PUT` / `DELETE` | offline / timeout | alert "Cần kết nối mạng để thay đổi sổ giỗ.", stays on the form |
| `POST` / `PUT` | 5xx | alert "Chưa lưu được. Vui lòng thử lại.", stays on the form |
| `POST /v1/memorials` | 409 `MEMORIAL_LIMIT_REACHED` | alert "Sổ giỗ đã đủ 100 người. Hãy xóa bớt trước khi thêm mới.", stays on the form |
| `POST` / `PUT` | 400 `VALIDATION_ERROR` | alert "Ngày này không có trong lịch. Vui lòng kiểm tra lại." when the server names a date field, otherwise "Chưa lưu được. Vui lòng thử lại." (only reachable if local checks of criteria 17–19 miss a case), stays on the form |
| `PUT /v1/memorials/{id}` | 404 `MEMORIAL_NOT_FOUND` | "Mục này không còn trong sổ giỗ.", form closes, list reloads (criterion 23) |
| `DELETE /v1/memorials/{id}` | 404 `MEMORIAL_NOT_FOUND` | "Mục này không còn trong sổ giỗ.", form closes, list reloads (criterion 26) |
| `POST` / `PUT` / `DELETE` | 401 | alert "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại." |
| push token register / remove, account time zone (⚠️ contract) | any | nothing shown; retried at the next trigger of criteria 30 / 34 |

## Out of scope (this feature boundary, not tracked here)

- The notification list screen, its unread badge and paging — `Docs/Specs/Notifications/` (ADR-0001).
- The account-wide notification switch UI — a settings feature; the server applies it (FR-MEM-008 @ v2.1).
- Computing and sending reminders, late reminders, punctuality — backend (ADR-0002, BR-MEM-13, NFR-MEM-04).
- Firebase project, APNs key upload and environments — infrastructure (ADR-0001 follow-ups; the product owner registers the Firebase project).
- The iOS Reminders app (FR-MEM-009 removed).
- Home's week-strip link itself — `Docs/Specs/Home/` (v1.7).
- The family-tree ("Gia phả") screens and creating entries from the tree — `genealogy` product spec; neither the empty state nor the list links to it for now (product owner, 2026-10-14).
- Sharing a book, search, export, soft delete (product §1.2).

## Pending (not yet implemented — see `tasks.md`)

Criteria the shipped code does **not** meet yet (drift against product spec v2.1):

- Criterion 2 — a guest sees the empty book (the 401 is swallowed) instead of a sign-in prompt (FR-MEM-001).
- Criterion 3 — the Me-tab sign-out already deletes the memorial cache (`ILSessionDataCleanerImpl` includes `ILMemorialMO`), but an expired session (`AppCoordinator.handleSessionExpired`) deletes only the user, and the cache is not tied to an account (criterion 39) (FR-MEM-010, BR-MEM-01).
- Criteria 4, 29–33 — no push at all: no Firebase SDK, no `aps-environment` entitlement, no permission prompt, no token registration, no deep link (FR-MEM-008, ADR-0001).
- Criteria 6, 12, 20, 27 — the form still has the "Thêm vào Lời nhắc (Reminders)" switch (default on), the highlight shows "có trong Lời nhắc", and saving with it on reports the Reminders-app message (FR-MEM-009 removed).
- Criterion 8 — the empty state still shows the "Lấy từ gia phả" card (FR-MEM-002).
- Criteria 6, 13 — no leap-month choice; the leap marker is always sent as `false` and dropped on load (BR-MEM-04).
- Criterion 15 — the year menu offers the current year and the 96 before it, not back to 1900 (BR-MEM-03).
- Criterion 18 — no client length limits; the server's 400 shows one generic message.
- Criterion 19 — a lunar day 30 in a 29-day month with a known year is silently saved as day 29 (`lunarToSolar` clamps), and a date after today is only caught by the server (generic message) (BR-MEM-03).
- Criteria 23, 26 — a 404 on save leaves the user on the form; a 404 on delete reports "Đã xóa…" instead of "Mục này không còn trong sổ giỗ.".
- Criteria 24 — delete happens immediately, no confirmation (BR-MEM-12).
- Criterion 28 — no mapping of out-of-range server reminder values (and ⚠️ product above).
- Criterion 34 — the time zone is not reported (no contract yet).
- Criterion 35 — `add_to_os_reminder` is still sent (`true` with a reminder by default); `reminder.timezone` is already not sent.
- Criteria 36–38 — only "offline" falls back to the cache, with no line; a 5xx or any other failure, and offline with no cache, show the empty state; offline writes show "Không có kết nối mạng. Vui lòng thử lại."; copy differs from §3.1.1 (e.g. book-full message).
- Criterion 40 — portrait upload (backend photo route not built; `TD-Memorial-002`, backend `TD-001`).
- Criterion 41 — vectors are not run; known mismatches before running: ordinal 0 is collapsed to `nil` (vector expects `0`), strict day-30 / leap conversion (criterion 19), no leap input.
- Criterion 43 — not measured.
- Visual QA on device (dark mode, long names, empty state, Dynamic Type).

## Open questions (resolved)

- ~~Keep the "Xem gia phả" button under a non-empty list (kept on 2026-10-05, not in product §3.1.1)?~~ → **No, removed for now** (anh Đức, 2026-10-14). Criterion 8. Resolved 2026-10-14.

- ~~Account-wide notification switch: push only, or the notification list too?~~ → push only, on every device of the account; memorial reminders still go into the notification list; the device's own permission is separate (product owner, 2026-10-14; product FR-MEM-008 @ v2.1). No memorial screen changes. Resolved 2026-10-14.
- ~~Reminder mechanism (local notifications, Reminders app) and its sub-questions (permission denied, another device's stale notification, Reminders-app item on edit/delete, duplicates, Reminders access denied)~~ → the server sends reminders to the notification list and as push (ADR-0001, ADR-0002, FR-MEM-008); the Reminders app is dropped (FR-MEM-009 removed); a device without push permission shows the §3.1.1 hint (criterion 29). Supersedes the v2.0 resolution of 2026-10-14 and `AS-Memorial-002`. Resolved 2026-10-14 by product spec v2.0.
- ~~Server reachable but failing (5xx): offline copy or error?~~ → offline copy with a line (FR-MEM-010, criterion 36). Resolved 2026-10-14 by product spec v2.0.
- ~~Server reminder values outside the fixed choices~~ → show the nearest choice, keep the stored value until saved (FR-MEM-007, criterion 28); the tie-break is still ⚠️ product. Resolved 2026-10-14 by product spec v2.0.
- ~~Copy for leap choice and marker, "too long", "date not valid", offline states, delete confirmation~~ → product §3.1.1 (criteria 6, 13, 18, 19, 24, 36–38). Resolved 2026-10-14 by product spec v2.0.
- ~~Saving or deleting an entry deleted elsewhere~~ → removed from the book with "Mục này không còn trong sổ giỗ." (FR-MEM-004, FR-MEM-005, criteria 23, 26). Resolved 2026-10-14 by product spec v2.0.
- ~~Reminder time zone~~ → the account time zone, reported from the device; no per-entry time zone (BR-MEM-11, ADR-0002, criteria 34–35). Replaces the v2.0 "send `reminder.timezone`". Resolved 2026-10-14.
- ~~Leap months~~ → product BR-MEM-04 / BR-MEM-05 (a death may be in a leap month; the anniversary is always in the regular month). Supersedes the 2026-10-03 "skip leap months" default (`AS-Memorial-003`). Resolved 2026-10-14 by product spec v1.0.
- ~~Delete safety~~ → product BR-MEM-12 (ask for confirmation). Supersedes the 2026-10-03 "delete immediately" default (`AS-Memorial-004`). Resolved 2026-10-14 by product spec v1.0.
- ~~Storage / source of truth / offline~~ → product BR-MEM-01 + FR-MEM-010 (account-owned book, offline read-only in the apps). Supersedes `AS-Memorial-001` (already invalidated) and `AS-Memorial-006`. Resolved 2026-10-14 by product spec v1.0.
- ~~Date-of-death mapping to the API~~ → product BR-MEM-03 / BR-MEM-04 / BR-MEM-10 for the rules; the wire mapping is in `design.md` "Server sync". Supersedes `AS-Memorial-005`. Resolved 2026-10-14.
- ~~Year range~~ → product BR-MEM-03 (1900 → current year). Replaces the prototype's 96-year menu. Resolved 2026-10-14.
- ~~Portrait source/storage~~ → product FR-MEM-011 (planned; JPEG/PNG/WebP ≤ 5 MB, apps convert HEIC to JPEG); deferred until the backend photo route exists (`TD-Memorial-002`). Resolved 2026-10-14.
- ~~API contract~~ → `/v1/memorials` (innerlamp-be `openapi.yaml`). Resolved 2026-10-07.
