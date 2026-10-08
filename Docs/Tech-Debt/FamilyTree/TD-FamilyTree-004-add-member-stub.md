---
id: TD-FamilyTree-004
title: Header "+" (add member) is wired to a TODO stub
title_vi: Nút "+" ở header (thêm thành viên) mới nối tới stub TODO
feature: FamilyTree
level: Medium
status: Resolved
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeCoordinator.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeHeaderView.swift
---

## Description / Mô tả
EN: The round "+" button in the tree header is built and sends `addTapped` -> `ILFamilyTreeNavEvent.addMember`, but the coordinator handler is a one-line `print("TODO: ...")` stub. There is no add-member form, relation picker or API.
VI: Nút "+" tròn ở header cây đã có và phát `addTapped` -> `ILFamilyTreeNavEvent.addMember`, nhưng handler trong coordinator chỉ là stub `print("TODO: ...")`. Chưa có form thêm thành viên, chọn quan hệ hay API.

## Why it was taken on / Lý do chấp nhận nợ
EN: The add-member flow is unconfirmed in requirements v2.0 (⚠️ Not confirmed); the button ships so the layout matches the design.
VI: Flow thêm thành viên chưa được xác nhận trong requirements v2.0 (⚠️ Not confirmed); nút vẫn được đưa vào để bố cục khớp design.

## Impact / Ảnh hưởng
EN: Tapping "+" does nothing visible.
VI: Bấm "+" không có phản hồi nào.

## Proposed fix / Hướng xử lý
EN: Spec the member form (fields, relation to an existing member, validation, API), then route `.addMember` to its coordinator.
VI: Viết spec form thành viên (trường, quan hệ với thành viên có sẵn, validate, API), rồi chuyển `.addMember` sang coordinator của form đó.

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-03 — header "+" now opens the `FamilyTreeAddMember` form (not committed yet). Saving is still a stub: TD-FamilyTreeAddMember-001.
VI: Đã xử lý 2026-10-03 — nút "+" ở header giờ mở form `FamilyTreeAddMember` (chưa commit). Việc lưu vẫn là stub: TD-FamilyTreeAddMember-001.
