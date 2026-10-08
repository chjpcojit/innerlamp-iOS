# Requirements — FamilyTreeCreate

Version: 1.0
Last updated: 2026-10-03
Status: implemented (build-verified; UI not run on device) — saving has no data source yet
Feature folder: `InnerLamp/Presentation/Scenes/FamilyTreeCreate/`

> Source of truth: `Docs/InnerLamp project/IL-GiaPha.dc.html` (screen "Tạo gia phả", `setupOpen` / `createClan()`).

## User Story

As someone starting my clan's family book, I want to enter the clan and its founder once, so that I
get a tree to which I can add descendants.

## Acceptance Criteria (EARS notation)

- WHEN the user taps "Tạo gia phả mới" on the empty family tree, THE SYSTEM SHALL open the "Tạo gia phả" form.
- THE SYSTEM SHALL show a header card ("Họ …" and "Quê gốc · Thủy tổ" by default) that updates as the user types: the clan name with "Họ " added when missing, and "quê gốc · Thủy tổ <tên>" from the filled fields.
- THE SYSTEM SHALL collect: tên dòng họ, quê gốc, thủy tổ (họ và tên, năm sinh, trạng thái "Đã mất" / "Còn sống"), and an optional vợ thủy tổ. The status defaults to "Đã mất".
- WHILE the status is "Đã mất", THE SYSTEM SHALL also ask for năm mất and an optional ngày giỗ (âm lịch); WHILE it is "Còn sống", THE SYSTEM SHALL hide them and ignore their values.
- THE SYSTEM SHALL accept only digits, at most four, in the year fields.
- WHEN the user taps "Tạo gia phả", THE SYSTEM SHALL validate in form order and, on the first failure, show that message under the field, scroll to it and focus it:
  - tên dòng họ empty → "Vui lòng nhập tên dòng họ."
  - quê gốc empty → "Vui lòng nhập quê gốc."
  - họ tên thủy tổ empty → "Vui lòng nhập họ tên thủy tổ."
  - năm sinh empty → "Vui lòng nhập năm sinh thủy tổ."; outside 1300 – current year → "Năm sinh chưa hợp lệ (1300–<năm>)."
  - (deceased) năm mất empty → "Vui lòng nhập năm mất (có thể ước lượng)."; before năm sinh or after the current year → "Năm mất phải sau năm sinh và không quá <năm>."
  - (deceased) ngày giỗ filled but not a day (1–30) plus a lunar month → "Ngày giỗ chưa hợp lệ. Ví dụ: 15 tháng Chạp." (`AS-FamilyTreeCreate-002`)
- WHEN the user edits any field after an error, THE SYSTEM SHALL clear the error.
- WHEN validation passes, THE SYSTEM SHALL build the tree — clan name (with "Họ "), quê gốc, the founder as đời 1 (male), and the wife if given (female, linked to the founder) — save it, then return to the family tree showing the new tree.
- WHILE saving, THE SYSTEM SHALL show the button as loading and ignore further taps.
- IF saving fails, THEN THE SYSTEM SHALL stay on the form and show the error.
- WHEN the user taps back, THE SYSTEM SHALL return to the family tree without creating anything.

## Out of Scope

- Persistence / API for the clan book (`TD-FamilyTreeCreate-001`).
- The confirmation toast and the "+" add-member button (`TD-FamilyTreeCreate-002`).
- "Tham gia bằng mã mời" (join by invite code).
