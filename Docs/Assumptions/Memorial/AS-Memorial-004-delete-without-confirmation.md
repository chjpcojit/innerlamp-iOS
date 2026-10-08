---
id: AS-Memorial-004
title: "Xóa khỏi sổ giỗ" deletes immediately, without a confirmation dialog
title_vi: "Xóa khỏi sổ giỗ" xóa ngay, không hỏi xác nhận
feature: Memorial
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Memorial/ILMemorialEditViewModel.swift:195
source: Docs/Specs/Memorial/requirements.md (Pending — delete safety, ⚠️ Not confirmed)
owner: Product / Design
---

## Assumption / Giả định
EN: Tapping the delete button removes the entry at once and shows the "Đã xóa … khỏi sổ giỗ." banner; there is no confirm step and no undo.
VI: Chạm nút xóa sẽ xóa mục ngay và hiện banner "Đã xóa … khỏi sổ giỗ."; không có bước xác nhận và không hoàn tác.

## Rationale / Cơ sở giả định
EN: The design prototype deletes immediately (`gdDelete`), and the user chose to follow it.
VI: Prototype thiết kế xóa ngay (`gdDelete`) và người dùng chọn làm theo.

## Implications if wrong / Hệ quả nếu sai
EN: An accidental tap loses a record that cannot be recovered. Fixing it is local to the form (add a dialog before `deleteTapped`).
VI: Chạm nhầm sẽ mất một bản ghi không khôi phục được. Sửa chỉ nằm trong form (thêm dialog trước `deleteTapped`).

## Validation / Cách xác nhận
EN: Confirm with Product / Design whether a dialog (`ILAlert.dialog`) is wanted.
VI: Xác nhận với Product / Design có cần dialog (`ILAlert.dialog`) hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
