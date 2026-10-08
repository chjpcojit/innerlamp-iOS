# Requirements — FamilyTreeAddMember

Version: 1.0
Last updated: 2026-10-03
Status: implemented (app target build-verified; unit tests written but not executed; UI not run on device) — saving has no data source yet
Feature folder: `InnerLamp/Presentation/Scenes/FamilyTreeAddMember/`

> Source of truth: `Docs/InnerLamp project/IL-GiaPha.dc.html` (screen "Thêm người vào gia phả", `openForm()` / `save()`).

## User Story

As a member of a clan, I want to add a relative to the family tree, so that the tree shows everyone in my family.

## Acceptance Criteria (EARS notation)

- WHEN the user taps "+" in the family-tree header, THE SYSTEM SHALL open the "Thêm người vào gia phả" form with the selected member (else the founder) as the relative and "Con của" selected.
- WHEN the user taps "Thêm con cháu" in a living member's detail sheet, THE SYSTEM SHALL open the same form with that member as the relative and "Con của" selected.
- THE SYSTEM SHALL let the user choose "Con của" or "Vợ / chồng của", show the relative (name, "Đời N" with "dâu"/"rể" for married-in people, "còn sống"/"đã mất") and let the user change the relative from a list of everyone in the tree.
- THE SYSTEM SHALL show a preview of the result: "Đời N · con của <cha> [và <mẹ>]" or "Đời N · vợ/chồng của <tên>".
- THE SYSTEM SHALL collect: họ và tên, giới tính (Nam/Nữ), năm sinh, trạng thái (default "Còn sống"), ghi chú. WHILE living it SHALL also ask nơi sinh sống hiện tại; WHILE deceased, năm mất, ngày giỗ (âm lịch, optional) and nơi an táng (optional).
- WHILE the relation is "Vợ / chồng của", THE SYSTEM SHALL set the gender opposite to the relative and not let the user change it.
- THE SYSTEM SHALL accept only digits, at most four, in the year fields.
- WHEN the user taps "Lưu" or "Thêm vào gia phả", THE SYSTEM SHALL validate and, on the first failure, show the message, scroll to the field and focus it:
  - relative missing → "Vui lòng chọn người trong gia phả."
  - họ và tên empty → "Vui lòng nhập họ và tên."
  - năm sinh empty → "Vui lòng nhập năm sinh."; outside 1700 – current year → "Năm sinh chưa hợp lệ (1700–<năm>)." (`AS-FamilyTreeAddMember-001`)
  - (deceased) năm mất empty → "Vui lòng nhập năm mất."; before năm sinh or after the current year → "Năm mất phải sau năm sinh và không quá <năm>."
  - (deceased) ngày giỗ filled but unreadable → "Ngày giỗ chưa hợp lệ. Ví dụ: 15 tháng Chạp."
  - (living) nơi sinh sống empty → "Vui lòng nhập nơi sinh sống hiện tại."
  - (child) the new person would be past generation 7 → "Gia phả hiện hiển thị tối đa 7 đời." (`AS-FamilyTreeAddMember-001`)
  - (spouse) relative married into the clan → "<tên> là dâu/rể trong họ. Hãy chọn người mang huyết thống."
  - (spouse) relative already has a spouse → "<tên> đã có chồng/vợ trong gia phả."
- WHEN the user edits any field after an error, THE SYSTEM SHALL clear the error.
- WHEN validation passes, THE SYSTEM SHALL add the person (child: attached to the relative, or to the relative's partner when the relative married in — `AS-FamilyTreeAddMember-002`; spouse: linked to the relative), save, return to the family tree and select the new person.
- WHILE saving, THE SYSTEM SHALL show the button as loading and ignore further taps. IF saving fails, THEN THE SYSTEM SHALL stay on the form and show the error.
- WHEN the user taps the close button, THE SYSTEM SHALL return to the family tree without adding anything.

## Out of Scope

- Persistence / API (`TD-FamilyTreeAddMember-001`).
- The saved-confirmation toast (`TD-FamilyTreeAddMember-002`).
- Editing or deleting an existing member.
