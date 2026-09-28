# Requirements — EditProfile

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full edit form with mock data + real client-side
validation; `saveProfile` is a stub, and 4 destinations are not built
Feature folder: `InnerLamp/Presentation/Scenes/EditProfile/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented EditProfile
> feature. It documents the shipped behavior, including the mock data, the
> stubbed `saveProfile`, and the unimplemented destinations.

## User Story

As a signed-in user, I want to edit my display name, temple, bio, and sangha
visibility, so that my profile reflects who I am and how much I share.

## Acceptance Criteria (EARS notation)

- WHEN the EditProfile screen loads, THE SYSTEM SHALL show an initials avatar
  with a camera badge, four labeled input cards (display name, read-only phone,
  temple, multi-line bio), the "Hiển thị trong đạo tràng" group (3 visibility
  rows), and a "Vùng cẩn trọng" (change password / delete account) section.
- WHEN the user types into the display name, THE SYSTEM SHALL update the
  initials and clear any prior validation error.
- WHEN the user taps "Lưu" (save) with an empty/whitespace display name, THE
  SYSTEM SHALL show an inline display-name error and NOT call save.
- WHEN the user taps "Lưu" with a valid display name, THE SYSTEM SHALL trim the
  fields, show a saving state, call the save use case, and then pop the screen
  on success.
- WHEN the user taps the back control or the save completes, THE SYSTEM SHALL
  close the EditProfile screen and return to the previous screen.
- WHEN the user taps "Đổi ảnh đại diện", a visibility row, "Đổi mật khẩu", or
  "Xóa tài khoản và toàn bộ dữ liệu", THE SYSTEM SHALL emit the corresponding
  navigation event.

## Out of scope (this feature boundary, not backend work)

- The avatar picker, visibility picker, change-password, and delete-account
  screens — each reaches a TODO in the coordinator.

## Pending (not yet implemented — see `tasks.md`)

- A real profile read/update API. `ILEditProfileUseCaseImpl.getProfile()`
  returns mock data, and `saveProfile(_:)` is a `print("TODO: …")` stub.
  (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the profile read/update API contract(s) — no profile
  > endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- Four unimplemented destinations: `.changeAvatar`, `.openVisibility`,
  `.changePassword`, and `.deleteAccount`.

- The single "Pháp danh hoặc tên gọi" field does not map cleanly to the Profile
  entity's separate `fullName` + `dharmaName` fields.

  > ⚠️ Not confirmed: how the single display-name field maps to the backend
  > (one field vs two) — blocks the save DTO.

## Open questions (resolved during implementation)

- ~~Is the phone number editable?~~ → No. It is read-only on this screen — it is
  the login identity, and changing it would need OTP re-verification. Resolved
  as an assumption during implementation (see the README).
