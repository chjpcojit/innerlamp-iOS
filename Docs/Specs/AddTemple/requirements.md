# Requirements — AddTemple

Version: 1.1
Last updated: 2026-10-11
Status: in-progress — UI + local validation + navigation done; address dropdowns use the server administrative-unit API; no proposal-submission API
Feature folder: `InnerLamp/Presentation/Scenes/AddTemple/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a person signing up who cannot find my temple in the ordination-place list, I want to add its
name and location, so that I can finish registering and InnerLamp can verify the temple later.

## Acceptance Criteria (EARS notation)

- WHEN the user taps "Không thấy chùa của bạn? Thêm thông tin chùa" in the sign-up ordination picker,
  THE SYSTEM SHALL open the "Thêm thông tin chùa" screen with the name field prefilled from the
  picker's search text.
- THE SYSTEM SHALL present province ("Tỉnh / thành phố") and ward ("Phường / xã") as dropdown fields
  that open a searchable bottom sheet whose options come from metadata; the ward field SHALL be disabled
  ("Chọn tỉnh / thành phố trước") until a province is chosen.
- WHEN the user changes the province, THE SYSTEM SHALL clear the chosen ward and reload the wards of the
  new province, showing a skeleton in the ward sheet while loading.
- WHEN the user taps "Gửi để duyệt" with an empty name, THE SYSTEM SHALL show "Nhập tên chùa." and mark
  the name field; WHEN the name is filled but no province is chosen, THE SYSTEM SHALL show
  "Chọn tỉnh / thành phố." and mark the province field; WHEN no ward is chosen, THE SYSTEM SHALL show
  "Chọn phường / xã." and mark the ward field.
- WHEN the name (ignoring case, diacritics and a leading "Chùa/Thiền viện/Tịnh xá/Niệm Phật đường") and
  province match a temple already in the loaded catalog, THE SYSTEM SHALL show
  "<tên chùa> đã có trong danh bạ. Quay lại và tìm để chọn." and not submit.
- WHEN the form is valid and submitted, THE SYSTEM SHALL return to the sign-up screen with the proposed
  temple selected as the ordination place and labelled "Đang chờ duyệt"; a name without a temple prefix
  SHALL get "Chùa " prepended.
- WHEN the user edits any field after an error, THE SYSTEM SHALL clear the error.
- WHEN the user taps "Hủy" or back, THE SYSTEM SHALL return to sign-up without changing the selection.

## Pending

- The dropdowns read `/v1/administrative-units/new/provinces` and `.../provinces/{code}/wards`
  (`TD-AddTemple-001` resolved). ⚠️ Not confirmed: whether ward is required (`AS-AddTemple-002`).

- ⚠️ Not confirmed: there is no API to submit a temple proposal; the proposal is kept on the device and
  only its name is sent as `ordination_place` at registration (`AS-AddTemple-001`, `TD-SignUp-002`).
- ⚠️ Not confirmed: whether the "suggest" mode of the prototype (opened from the temple finder, with a
  "Đã gửi đề xuất" confirmation page) is wanted; it is not built.
