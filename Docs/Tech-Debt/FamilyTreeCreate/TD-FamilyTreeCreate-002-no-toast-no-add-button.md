---
id: TD-FamilyTreeCreate-002
title: No success toast, and the footnote mentions a "+" button that does not exist yet
title_vi: Chưa có toast thành công, và dòng chú thích nhắc nút "+" chưa tồn tại
feature: FamilyTreeCreate
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTreeCreate/ILFamilyTreeCreateViewController.swift
  - InnerLamp/Resources/Localization/vi.json
---

## Description / Mô tả
EN: The design shows a toast "Đã tạo gia phả <tên>. Bấm + để thêm con cháu." on the tree after creating. It is not built (the tree screen has no toast and no "+" button — `TD-FamilyTree-002`). The form's footnote "Sau khi tạo, bạn thêm con cháu từng đời bằng nút +" is kept as designed, so it points at a button that is not there yet.
VI: Design hiện toast "Đã tạo gia phả <tên>. Bấm + để thêm con cháu." trên màn cây sau khi tạo. Chưa làm (màn cây chưa có toast và chưa có nút "+" — `TD-FamilyTree-002`). Dòng chú thích "Sau khi tạo, bạn thêm con cháu từng đời bằng nút +" giữ đúng design nên đang trỏ tới nút chưa tồn tại.

## Why it was taken on / Lý do chấp nhận nợ
EN: Both depend on the add-member flow, which has no spec yet.
VI: Cả hai phụ thuộc flow thêm thành viên, chưa có spec.

## Impact / Ảnh hưởng
EN: After creating, the user lands on the new tree with no confirmation and no way to add descendants.
VI: Sau khi tạo, người dùng vào cây mới mà không có xác nhận và chưa thể thêm con cháu.

## Proposed fix / Hướng xử lý
EN: Build the add-member flow (`TD-FamilyTree-002`), then add a toast on the tree screen and keep or reword the footnote.
VI: Làm flow thêm thành viên (`TD-FamilyTree-002`), rồi thêm toast ở màn cây và giữ hoặc sửa lại dòng chú thích.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
