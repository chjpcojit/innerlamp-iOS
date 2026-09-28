# Requirements — Temple

Version: 2.0
Last updated: 2026-09-28
Status: in-progress — full detail screen with a static catalog; the
list/discovery scope from `SRS.md` is not built
Feature folder: `InnerLamp/Presentation/Scenes/Temple/`

> See `changelog.md` in this folder for the version history of this spec.

> `SRS.md` in this folder is an upstream business requirements document (from
> `il-ba`) that describes a **larger** feature — a discovery/list screen plus
> this detail screen. Only the **detail** screen is implemented; the
> list/discovery half (`FR-001`–`FR-012` in `SRS.md`) is not.

## User Story

As a practitioner, I want to view a temple's full profile (identity, opening
status, history, organization, architecture, amenities, visiting rules,
upcoming sessions, location and contacts), so that I can decide whether and how
to visit a temple from the Home carousel or the Sangha community card.

## Acceptance Criteria (EARS notation)

- WHEN the Temple screen loads for a given temple id, THE SYSTEM SHALL show a
  hero with the cấp-di-tích and hệ-phái chips, the temple name, an optional
  "Còn gọi: …" alias line, and a district/province place line.
- WHEN the Temple screen loads, THE SYSTEM SHALL show 3 buttons — "Theo dõi"
  (or "Đang theo dõi"), "Chỉ đường", and "Cúng dường".
- WHEN the Temple screen loads, THE SYSTEM SHALL show a status card with the
  current open/closed state, the current time compared against today's
  opening hours (using the Rằm/Mùng Một hours on those lunar days), the
  distance from a fixed reference location, and both the weekday and
  Rằm/Mùng-Một hour rows with a "Hôm nay" badge on whichever applies.
- WHEN the Temple screen loads, THE SYSTEM SHALL show a 4-tile facts grid
  (Niên đại, Cấp di tích, Hệ phái, Vùng miền).
- WHEN the Temple screen loads, THE SYSTEM SHALL show a "Giới thiệu" biography
  collapsed to a fixed height with a "Đọc thêm"/"Thu gọn" toggle that only
  appears when the biography overflows the collapsed height.
- WHEN the Temple screen loads, THE SYSTEM SHALL show "Tổ chức & truyền thừa"
  (Trụ trì, Tổ khai sơn, Giáo hội), each field showing "Đang cập nhật" in
  place of a missing value rather than hiding the row.
- WHEN the Temple screen loads, THE SYSTEM SHALL show "Kiến trúc & di sản"
  (architecture style + materials, and a card per highlight).
- WHEN the Temple screen loads, THE SYSTEM SHALL show a 5-tile "Tiện ích" grid
  (Bãi đỗ ô tô, Giữ xe máy, Cơm chay, Kinh sách, Khóa tu), each tile showing a
  green check when available or a "Không có" empty state otherwise.
- WHEN the Temple screen loads, THE SYSTEM SHALL show a "Lưu ý khi viếng thăm"
  card with the visit rules numbered "01", "02", ….
- WHEN the Temple screen loads AND the temple has upcoming sessions, THE
  SYSTEM SHALL show them under "Sự kiện & khóa học"; WHEN it has none, THE
  SYSTEM SHALL show a dashed empty-state box instead.
- WHEN the Temple screen loads, THE SYSTEM SHALL show "Vị trí & liên hệ" — a
  map placeholder, the full address, region line, coordinates, Google Maps
  and Apple Maps buttons, and Hotline/Fanpage/Website/Email rows (each
  showing "Đang cập nhật" and not tappable when the value is missing).
- WHEN the Temple screen loads, THE SYSTEM SHALL show a footer with the last
  data-update label.
- WHEN the user taps "Theo dõi"/"Đang theo dõi", THE SYSTEM SHALL flip the
  button label immediately (optimistic) and invoke the follow toggle
  (currently a stub — see Pending).
- WHEN the user taps "Chỉ đường" or the "Google Maps" button, THE SYSTEM SHALL
  emit a request to open Google Maps directions to the temple's coordinates.
- WHEN the user taps the "Apple Maps" button, THE SYSTEM SHALL emit a request
  to open Apple Maps directions to the temple's coordinates.
- WHEN the user taps a contact row that has a value, THE SYSTEM SHALL emit a
  request to open the matching system app (phone dialer, browser, or mail
  composer); WHEN the row has no value, THE SYSTEM SHALL do nothing.
- WHEN the user taps "Cúng dường", THE SYSTEM SHALL emit an offer event.
- WHEN the user taps "Xem tất cả" or the empty-state box under "Sự kiện & khóa
  học", THE SYSTEM SHALL emit an events event.
- WHEN the user taps an upcoming session, THE SYSTEM SHALL emit a session
  event carrying the session id.
- WHEN the user taps "Đọc thêm"/"Thu gọn", THE SYSTEM SHALL expand/collapse
  the biography.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Temple
  screen and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The temple **list/discovery** screen (top temples, paginated directory,
  filters, search, infinite scroll) — described in `SRS.md` `FR-001`–`FR-012`
  but **not implemented**. This is a separate future feature.
- The Offer screen (`.offer`), the events & courses screen (`.events`), and
  the session-detail / reader screen (`.session(id:)`) — each reaches a TODO.
- Requesting real location permission — distance is computed from a fixed
  reference point (Quận 1, TP.HCM), matching the design handoff prototype.
- A real interactive map — the location card shows a static placeholder.
- "Báo thông tin sai" in the footer has no defined destination in the design
  handoff either, so it is rendered without an action.

## Pending (not yet implemented — see `tasks.md`)

- A real temple API. `ILTempleUseCaseImpl.getInitialState` returns a static
  9-temple catalog transcribed from the design handoff's `TEMPLE_INFO`.
  (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the temple list/detail API contract(s) — `SRS.md`
  > proposes `GET /v1/temples`, `/top`, `/{id}` but none are in
  > `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- `toggleFollow` is a stub (`print("TODO: …")`) — following a temple needs a
  repository of followed temples; today the button label only toggles
  in-memory for the current screen session.

- The `.offer`, `.events`, and `.session(id:)` destinations are TODOs.

- Real location permission + a real map view (currently a static placeholder
  and a fixed reference coordinate).

- Loading / error / offline states not rendered.

## Open questions (resolved during implementation)

- ~~Is the full discovery feature (list + filters + search) part of what
  shipped?~~ → No. Only the detail screen shipped. `SRS.md` describes the full
  feature; the code implements the detail screen only, reached from the Home
  carousel and the Sangha community card. Resolved 2026-09-27 while writing
  v1.0 of this spec.
- ~~Does "Cấp di tích" ever differ between the hero chip and the facts-grid
  tile?~~ → No, both read the same `rank` field and share the same
  `nil` → "Chưa xếp hạng" (hero) / "Đang cập nhật" (facts grid) fallback text,
  matching the two different fallback strings used in the design handoff for
  the same underlying `null` value. Resolved 2026-09-28 while redesigning the
  screen to match `Component.TEMPLE_INFO`.
