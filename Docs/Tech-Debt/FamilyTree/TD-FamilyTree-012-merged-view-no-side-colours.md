---
id: TD-FamilyTree-012
title: The merged "Nội – ngoại" view does not colour the two sides
title_vi: View gộp "Nội – ngoại" chưa tô màu hai bên
feature: FamilyTree
level: Low
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeLegendView.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeCanvasView.swift
---

## Description / Mô tả
EN: The prototype draws the father's line with dark-brown branches and the mother's line with terracotta ones, tints the medallion trims the same way and lists "Bên nội / Bên ngoại" in the legend. The app places the sides left (nội) and right (ngoại), writes the side in every label ("Ông nội", "Bà ngoại") and shows only "BẠN" and "Còn sống" in the legend.
VI: Prototype vẽ bên cha bằng cành nâu đậm, bên mẹ bằng cành đất nung, tô viền medallion tương ứng và ghi "Bên nội / Bên ngoại" trong chú giải. App đặt bên nội bên trái, bên ngoại bên phải, ghi bên trong mỗi nhãn ("Ông nội", "Bà ngoại") và chú giải chỉ có "BẠN" và "Còn sống".

## Why it was taken on / Lý do chấp nhận nợ
EN: Per-side colours need a side per branch in the layout/canvas plus new colour assets; the side is already readable from position and text.
VI: Tô màu theo bên cần thêm thông tin bên cho từng cành trong layout/canvas và asset màu mới; bên đã đọc được qua vị trí và chữ.

## Impact / Ảnh hưởng
EN: Cosmetic only: the two lines are harder to tell apart at a glance on a big tree.
VI: Chỉ thẩm mỹ: khó phân biệt nhanh hai bên trên cây lớn.

## Proposed fix / Hướng xử lý
EN: Add `side` to `ILFamilyTreeLayout.Branch` and `ILFamilyTreeNodeModel`, two bark/trim colour assets, and the two legend items.
VI: Thêm `side` vào `ILFamilyTreeLayout.Branch` và `ILFamilyTreeNodeModel`, hai asset màu cành/viền và hai mục chú giải.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
