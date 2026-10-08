# Requirements — TempleFinder

Version: 1.0
Last updated: 2026-10-05
Status: in-progress — UI + local logic done; proposal not sent (no API); on-device QA and test run pending
Feature folder: `InnerLamp/Presentation/Scenes/TempleFinder/`

> See `changelog.md` in this folder for the version history of this spec.

> Written retroactively from the implemented screen ("Chọn chùa tu tập", prototype screen `findtp`,
> pick mode).

## User Story

As a practitioner, I want to change my practice temple by searching the whole temple directory — and
to suggest a temple that is not listed yet — so that the Chùa tab always shows the temple I actually
practise at.

## Acceptance Criteria (EARS notation)

- WHEN the user taps "Đổi chùa" in the Chùa tab, THE SYSTEM SHALL open the "Chọn chùa tu tập" screen
  showing the current temple ("Chùa hiện tại: …") and keep the current choice until another is picked.
- WHEN the screen opens, THE SYSTEM SHALL load every temple of the directory and list them with a
  "Chọn" button, showing "Chùa của bạn" instead of the button on the current temple.
- WHEN the user types in the search field, THE SYSTEM SHALL list only temples whose name or address
  contains the text, ignoring case and diacritics.
- WHEN the user selects a region chip, THE SYSTEM SHALL list only temples of that region ("Tất cả" = no
  region filter); search and region combine.
- WHEN no temple matches, THE SYSTEM SHALL show a "no match" message above the "Không thấy chùa bạn
  tìm?" row.
- WHEN the user taps "Chọn" on a temple, THE SYSTEM SHALL save it as the practice temple, close the
  screen, and the Chùa tab SHALL show that temple.
- WHEN the user taps a temple row, THE SYSTEM SHALL open that temple's page.
- WHEN the user taps "Không thấy chùa bạn tìm?", THE SYSTEM SHALL show the "Đề xuất thêm chùa" form
  (name pre-filled from the search text; address, province, phone).
- WHEN the user submits the form without a name or without a province, THE SYSTEM SHALL mark that field
  with an error message and keep the form open.
- WHEN the submitted name and province match a temple already listed, THE SYSTEM SHALL reject it with
  "… đã có trong danh sách".
- WHEN the form is valid, THE SYSTEM SHALL close it and show "Đã gửi đề xuất “…”. InnerLamp sẽ xác minh
  và thêm vào danh bạ trong 3–5 ngày."
- IF the directory cannot be loaded, THE SYSTEM SHALL show an error (offline variant when applicable)
  with a "Thử lại" button.
- WHEN the user taps back, THE SYSTEM SHALL close the screen without changing the practice temple.

## Pending (not yet implemented — see `tasks.md`)

- Sending / storing the temple proposal.

  > ⚠️ Not confirmed: no API to submit a proposed temple (backend has list / top / detail only).
  > The form currently validates and shows the "sent" message without sending anything
  > (`Docs/Assumptions/TempleFinder/AS-TempleFinder-001-*.md`).

- Whether submitting a proposal also selects it as the practice temple (prototype: "Gửi và chọn chùa này"
  + a "Chờ xác minh" state on the Chùa tab).

  > ⚠️ Not confirmed: needs a stored proposal to select; not implemented.

## Open questions

- Should search also match aliases / district / province as in the prototype? The list API returns the
  address only (aliases are in the detail response) — `Docs/Tech-Debt/TempleFinder/TD-TempleFinder-002-*.md`.
