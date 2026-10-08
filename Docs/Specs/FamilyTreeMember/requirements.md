# Requirements — FamilyTreeMember

Version: 1.0
Last updated: 2026-10-04
Status: implemented (code written; build, unit tests and device run pending) — saving has no data source yet
Feature folder: `InnerLamp/Presentation/Scenes/FamilyTreeMember/`

> Source of truth: `Docs/InnerLamp project/IL-GiaPha.dc.html` (screen "Hồ sơ thành viên", `pfView` / `pfEditing` blocks).

## User Story

As a member of a clan, I want to open one person's full profile from the family tree and correct their details, so that the clan book stays accurate.

## Acceptance Criteria (EARS notation)

- FTM-1: WHEN the user taps "Hồ sơ đầy đủ" in a person's detail sheet, THE SYSTEM SHALL open the profile of that person in view mode.
- FTM-2: THE SYSTEM SHALL show in view mode: medallion (with the clan-head seal), name, meta line, status chip, role chip (Thủy tổ / Tộc trưởng) and a "Với bạn" chip when the relation to the viewer is known.
- FTM-3: THE SYSTEM SHALL show a THÔNG TIN card with Sinh – mất, Ngày giỗ (when known), Đang sống tại (living) or Nơi an táng (deceased) — "Chưa cập nhật" when empty —, Pháp danh and Bài vị thờ tại (only when filled) and Chi.
- FTM-4: THE SYSTEM SHALL show TIỂU SỬ with the biography, or a dashed box "Chưa có tiểu sử…" that opens edit mode when tapped; WHILE the person is deceased it SHALL show the TƯỞNG NIỆM tiles (Nhắc giỗ, Thắp đèn, Tụng kinh); it SHALL list QUAN HỆ rows and, WHEN a row is tapped, return to the tree with that person selected.
- FTM-5: WHEN the user taps "Sửa" (or the empty biography box), THE SYSTEM SHALL switch the same screen to edit mode with the form filled from the person: CƠ BẢN (họ và tên, giới tính, năm sinh, trạng thái, nơi sống when living), TƯỞNG NIỆM (năm mất, ngày giỗ âm lịch, nơi an táng — only when deceased), TÂM LINH (pháp danh, bài vị thờ tại), TIỂU SỬ.
- FTM-6: WHEN the user taps "Lưu" or "Lưu thay đổi", THE SYSTEM SHALL validate and, on the first failure, show the message under the field, scroll to it and focus it:
  - họ và tên empty → "Vui lòng nhập họ và tên."
  - năm sinh typed outside 1700 – current year → "Năm sinh chưa hợp lệ (1700–<năm>)." (empty is allowed) (`AS-FamilyTreeMember-002`)
  - (deceased) năm mất empty → "Vui lòng nhập năm mất."; before năm sinh or after the current year → "Năm mất phải sau năm sinh và không quá <năm>."
  - (deceased) ngày giỗ filled but unreadable → "Ngày giỗ chưa hợp lệ. Ví dụ: 15 tháng Chạp."
- FTM-7: THE SYSTEM SHALL accept only digits, at most four, in the year fields, and clear a shown error when the user edits any field.
- FTM-8: WHEN validation passes, THE SYSTEM SHALL save, update the profile, return to view mode and tell the family tree so it shows the updated person; WHILE saving it SHALL show the button as loading. IF saving fails, THEN THE SYSTEM SHALL stay in edit mode and show the error.
- FTM-9: WHEN the status is "Còn sống", THE SYSTEM SHALL clear death year, anniversary and burial place; WHEN "Đã mất", it SHALL clear the residence.
  > ⚠️ Not confirmed: field contract for Pháp danh and Bài vị thờ tại (`AS-FamilyTreeMember-001`).
- FTM-10: WHEN the user taps "Hủy" (the back chip in edit mode), THE SYSTEM SHALL discard the edits and return to view mode; WHEN the user taps back in view mode, THE SYSTEM SHALL return to the family tree.

## Out of Scope

- Persistence / API (`TD-FamilyTreeMember-001`).
- Portrait photo (`TD-FamilyTreeMember-002`).
- Destinations of Nhắc giỗ / Thắp đèn / Tụng kinh and the temple link (`TD-FamilyTreeMember-003`).
- Deleting a person; changing parent or spouse.
