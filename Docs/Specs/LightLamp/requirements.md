# Requirements — LightLamp

Version: 1.3
Last updated: 2026-10-11
Status: implemented (build-verified, tests written but not run) — local-only data, no API contract
Feature folder: `InnerLamp/Presentation/Scenes/LightLamp/`

> See `changelog.md` in this folder for the version history of this spec.
> Derived from `SRS.md` (v0.1) in this folder; `FR-*` IDs match the SRS.

## User Story

As a practitioner, I want to light a symbolic lamp with an intention and dedicate its merit to
someone, and see my lamps in a garden, so that I can keep a simple daily act of dedication.

## Acceptance Criteria (EARS notation)

### Thắp đèn (lighting screen)

- WHEN the lighting screen opens, THE SYSTEM SHALL show an unlit lamp on the hero stage, the headline
  "Thắp một ngọn đèn, hồi hướng cho người thương", a line with the number of the user's active lamps
  (or "Ngọn đèn sẽ sáng trong Vườn đèn" when none), the option groups and the "Thắp đèn" button. (FR-001)
- WHEN the form opens, THE SYSTEM SHALL preselect "Đèn dầu", "Cầu an" and "7 ngày". (FR-002)
- WHEN the user taps an option in the kind, intention or duration group, THE SYSTEM SHALL select it
  exclusively; for a kind change THE SYSTEM SHALL update the kicker "ĐÈN · <KIND>" and the lamp
  artwork. (FR-002)
- WHEN the dedication target is empty or whitespace only at lighting time, THE SYSTEM SHALL dedicate
  the lamp to "Tất cả chúng sanh". (FR-003)
- WHEN the vow is empty, THE SYSTEM SHALL light the lamp without a vow. (FR-003)
- WHEN the user taps "Thắp đèn", THE SYSTEM SHALL disable the button, show "Đang thắp…", ignite the lamp
  artwork, save the lamp, and then show the completion state; WHILE lighting, THE SYSTEM SHALL ignore
  further taps. (FR-004)
- WHEN the lamp has been lit, THE SYSTEM SHALL show "Đèn đã được thắp", a caption (kind · intention ·
  days), the dedication line "Nguyện đem công đức này hồi hướng cho <target | tất cả chúng sanh>", the
  vow in quotation marks when present, and the actions "Thắp thêm đèn" and "Vào vườn đèn". (FR-005)
- WHEN the user taps "Thắp thêm đèn", THE SYSTEM SHALL return to the form with an unlit lamp, empty
  target and vow, and the previous kind, intention and duration kept. (FR-006)
- IF saving the lamp fails, THEN THE SYSTEM SHALL show an error, keep the form values and not add a
  lamp. (FR-012)

### Vườn đèn (garden screen)

- WHEN the garden opens, THE SYSTEM SHALL show the subtitle "<N> ngọn đèn đang sáng", the filter chips
  and one card per active lamp (artwork, kind chip, "Của bạn · <intention>", "Cho <target>", remaining
  time), highlighting the user's own lamps. (FR-008)
- WHEN a lamp has more than one day left, THE SYSTEM SHALL show "Còn N ngày"; WHEN one day or less,
  "Sáng đến hết hôm nay". (FR-008)
- WHEN the user taps a filter chip, THE SYSTEM SHALL show only lamps of that kind and reset paging.
  Chips are "Tất cả" plus one per kind, each with its count. (FR-009)
- WHEN more than 12 lamps match, THE SYSTEM SHALL show the first 12 and a "Xem thêm đèn" button that
  appends the next 12. (FR-009)
- WHEN no active lamp matches, THE SYSTEM SHALL show an empty state with a way to light a lamp. (FR-013)

### Navigation

- WHEN the user taps "Vườn đèn" in the lighting header or "Vào vườn đèn" in the completion state, THE
  SYSTEM SHALL open the garden. (FR-007)
- WHEN the user taps "Thắp đèn" in the garden header, THE SYSTEM SHALL open a fresh lighting form. (FR-010)

### Data

- THE SYSTEM SHALL compute a lamp's remaining days from its lit date and duration and SHALL NOT list
  elapsed lamps. (FR-011)
- WHEN a lamp is lit, THE SYSTEM SHALL keep it across app restarts. (FR-012)
- WHEN the user signs out from Profile, THE SYSTEM SHALL delete all locally stored lamps. (FR-014)
  Lamps are mock local data today; once a lamp API exists they are loaded from the server.

## Out of scope (this feature boundary, not backend work)

- Paid temple offering, donation form and receipt — owned by `Offering` (separate spec, unchanged).
- "Thỉnh đèn tại chùa" card — depends on the donation flow.
- Community lamps from other users and any server-side lamp API.

## Pending (not yet implemented — see `tasks.md`)

- Device verification of visuals and animation; running the unit tests (`TD-LightLamp-003`, `TD-LightLamp-004`).

> ⚠️ Not confirmed: maximum length of the dedication target and the vow — blocks input limits and card truncation (Phase 2).

> ⚠️ Not confirmed: entry points beyond the Home "Thắp đèn — Vu Lan" row and the center tab-bar lamp button (e.g. Memorial, Temple). The center button opens Thắp đèn per the product owner's instruction (2026-10-11, `AS-LightLamp-005`); Chuẩn bị thiền stays reachable from the Home meditation row and the Meditation hub/Talk screens.

> ⚠️ Not confirmed: source of community lamps in the garden — blocks any non-local data. Interim: own lamps only.

> ⚠️ Not confirmed: real-time expiry vs static duration label — blocks FR-011. Interim: real-time expiry.

> ⚠️ Not confirmed: owner name shown on the user's lamps (prototype hardcodes "Tâm Minh") — blocks the persisted owner name. Interim (v1.1): no name is stored; cards show "Của bạn" because the app has no real display-name source (TD-Home-002).

> ⚠️ Not confirmed: empty-garden copy and layout (not in the prototype) — blocks FR-013 UI.

> ⚠️ Not confirmed: whether the "Thỉnh đèn tại chùa" card shows on the completion state — Interim: hidden.

## Open questions (resolved during implementation)

- ~~Scope of this iteration~~ → Thắp đèn + Vườn đèn only. Resolved 2026-10-10.
- ~~Where lit lamps are stored~~ → local Core Data behind a repository protocol. Resolved 2026-10-10.
- ~~Relation to `Docs/Specs/Offering/`~~ → new feature `LightLamp`; Offering untouched. Resolved 2026-10-10.
