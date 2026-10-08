---
id: TD-FamilyTreeAddMember-002
title: Saved-confirmation toast from the design is not shown
title_vi: Toast xác nhận đã lưu trong design chưa hiển thị
feature: FamilyTreeAddMember
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeCoordinator.swift
---

## Description / Mô tả
EN: The prototype shows a toast after saving; the app only pops back and selects the new person.
VI: Prototype hiện toast sau khi lưu; app chỉ quay lại và chọn người mới.

## Why it was taken on / Lý do chấp nhận nợ
EN: No shared toast component exists yet; the new node being selected is already visible feedback.
VI: Chưa có component toast dùng chung; việc chọn node mới đã là phản hồi nhìn thấy được.

## Impact / Ảnh hưởng
EN: Slightly less feedback than the design.
VI: Phản hồi ít hơn design một chút.

## Proposed fix / Hướng xử lý
EN: Add a shared toast to the design system and show it from the tree screen after `showTree(_:selecting:)`.
VI: Thêm toast dùng chung vào design system và hiện ở màn cây sau `showTree(_:selecting:)`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
