---
id: TD-FamilyTree-005
title: Anniversary reminder pill and contextual bottom pill are TODO stubs
title_vi: Nút nhắc giỗ và nút phụ cuối sheet là stub TODO
feature: FamilyTree
level: Medium
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeCoordinator.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeDetailSheetView.swift
---

## Description / Mô tả
EN: The TƯỞNG NIỆM pill ("Nhắc giỗ hằng năm" / "Bổ sung ngày giỗ") and the outlined bottom pill ("Nhắc ngày giỗ" for the deceased, "Thêm con cháu" for the living) send `.remindAnniversary(memberID:)` / `.addDescendant(memberID:)`. The coordinator handles both with a one-line `print("TODO: ...")`. The pill never shows the "✓ Đã có trong Sổ giỗ · Mở" state because the tree has no link to the Sổ giỗ book.
VI: Nút trong thẻ TƯỞNG NIỆM ("Nhắc giỗ hằng năm" / "Bổ sung ngày giỗ") và nút viền cuối sheet ("Nhắc ngày giỗ" cho người đã mất, "Thêm con cháu" cho người còn sống) phát `.remindAnniversary(memberID:)` / `.addDescendant(memberID:)`. Coordinator xử lý cả hai bằng một dòng `print("TODO: ...")`. Nút không bao giờ hiện trạng thái "✓ Đã có trong Sổ giỗ · Mở" vì cây chưa liên kết với Sổ giỗ.

## Why it was taken on / Lý do chấp nhận nợ
EN: Destinations (Sổ giỗ hand-off, add-descendant form) are unconfirmed (⚠️ Not confirmed in requirements v2.0).
VI: Đích đến (chuyển sang Sổ giỗ, form thêm con cháu) chưa được xác nhận (⚠️ Not confirmed trong requirements v2.0).

## Impact / Ảnh hưởng
EN: Both pills are inert.
VI: Hai nút này chưa có tác dụng.

## Proposed fix / Hướng xử lý
EN: Hand off to the Memorial create flow (pre-filled with the member and lunar date) and to the add-member form; derive the "already in the book" state from the Memorial repository.
VI: Chuyển sang flow tạo mục Sổ giỗ (điền sẵn thành viên và ngày âm) và form thêm thành viên; lấy trạng thái "đã có trong sổ" từ Memorial repository.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_

## Update / Cập nhật
EN: 2026-10-03 — the "Thêm con cháu" pill (`.addDescendant`) now opens the `FamilyTreeAddMember` form with that member as the relative. Only the "Nhắc ngày giỗ" stub remains here.
VI: 2026-10-03 — nút "Thêm con cháu" (`.addDescendant`) giờ mở form `FamilyTreeAddMember` với thành viên đó làm người liên quan. Mục này chỉ còn stub "Nhắc ngày giỗ".
