# Requirements — FamilyTreeChronicle

Version: 1.0
Last updated: 2026-10-04
Status: implemented (written, not yet built or run — verification pending) — saving has no data source yet
Feature folder: `InnerLamp/Presentation/Scenes/FamilyTreeChronicle/`

> Source of truth: `Docs/InnerLamp project/IL-GiaPha.dc.html` (screen "Phả ký dòng họ", `pkOpen` / `pkVals()`).

## User Story

As a member of a clan, I want to read and write the clan's chronicle (origin, history, shrine, house sayings), so that the family's story is kept next to its tree.

## Acceptance Criteria (EARS notation)

- WHEN the user taps the red 譜 seal in the family-tree header, or the "Phả ký dòng họ" row in the book-switcher menu, THE SYSTEM SHALL open the "Phả ký" screen for the book on display.
- WHEN the user has more than one book, THE SYSTEM SHALL show one tab per book ("<họ> · nội" / "<họ> · ngoại"); WHEN a tab is picked, THE SYSTEM SHALL show that book's chronicle in view mode.
- THE SYSTEM SHALL show: the 譜 seal, clan name, hometown and "N đời · M người · từ năm Y"; NGUỒN GỐC (founder card + origin text); MỐC LỊCH SỬ (timeline, oldest first); NHÀ THỜ HỌ (name, address, "Trưởng họ" with "Đổi", "Giỗ tổ", "Chạp họ"); GIA HUẤN (hoành phi, câu đối, lời dạy); NGƯỜI TIÊU BIỂU (up to 4 people with a note, or the clan head); a footnote.
- WHEN a section has no text yet, THE SYSTEM SHALL show a dashed "Chưa có … Bấm để …" placeholder; WHEN the user taps it, THE SYSTEM SHALL enter edit mode (this is how a first entry is added).
- WHEN the user taps "Sửa", THE SYSTEM SHALL enter edit mode: hometown, origin, milestones (year + event, add "+ Thêm mốc", delete ✕), shrine name / address / chạp họ, hoành phi (Han + reading), câu đối (two lines) and lời dạy become editable, and a notice "Đang sửa phả ký. Bấm Xong để lưu." is shown.
- THE SYSTEM SHALL accept only digits, at most four, in a milestone year.
- WHEN the user taps "Xong", THE SYSTEM SHALL validate and, on failure, show the message under the milestone year, scroll to it and focus it:
  - year later than the current year, or unreadable → "Năm chưa hợp lệ (tối đa <năm>)." (`AS-FamilyTreeChronicle-003`)
- WHEN validation passes, THE SYSTEM SHALL trim the text, drop milestones that are completely empty, save, return to view mode and show a "Đã lưu phả ký <họ>." confirmation. WHILE saving it SHALL ignore further taps; IF saving fails, THEN THE SYSTEM SHALL stay in edit mode and show the error.
- WHEN the user taps "Đổi" next to "Trưởng họ", THE SYSTEM SHALL list the living men of the blood line below the founder (`AS-FamilyTreeChronicle-001`), marking the current head "Hiện tại" (not selectable).
- WHEN the user picks a candidate, THE SYSTEM SHALL ask "Chuyển tộc trưởng?" with who steps down and who takes over; WHEN confirmed, THE SYSTEM SHALL move the clan-head flag to the new person, save and confirm "Đã chuyển tộc trưởng sang <tên>."
- WHEN the founder has a known death anniversary, THE SYSTEM SHALL show "Nhắc giỗ tổ hằng năm" (stub — `TD-FamilyTreeChronicle-003`).
- WHEN the user taps the founder card, the keeper or a notable person, THE SYSTEM SHALL return to the family tree and select that person.
- WHEN the user taps back, THE SYSTEM SHALL return to the family tree.
- Everyone who can open a book can edit its chronicle (`AS-FamilyTreeChronicle-002`).

## Out of Scope

- Persistence / API (`TD-FamilyTreeChronicle-001`), shrine photo (`TD-FamilyTreeChronicle-002`), Sổ giỗ hand-off (`TD-FamilyTreeChronicle-003`), unsaved-changes prompt (`TD-FamilyTreeChronicle-004`).
