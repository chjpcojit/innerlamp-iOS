---
id: TD-FamilyTree-006
title: "Thắp đèn" and "Tụng kinh" tiles are TODO stubs
title_vi: Ô "Thắp đèn" và "Tụng kinh" là stub TODO
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
EN: The two tiles of the TƯỞNG NIỆM card send `.lightLamp(memberID:)` and `.chant(memberID:)`; the coordinator only prints a TODO line.
VI: Hai ô trong thẻ TƯỞNG NIỆM phát `.lightLamp(memberID:)` và `.chant(memberID:)`; coordinator chỉ in một dòng TODO.

## Why it was taken on / Lý do chấp nhận nợ
EN: It is not confirmed which screens they open (Bell / Reader / Memorial hand-off) or what is passed along.
VI: Chưa xác nhận chúng mở màn nào (Chuông mõ / Đọc kinh / Sổ giỗ) và truyền dữ liệu gì.

## Impact / Ảnh hưởng
EN: Tiles are inert.
VI: Hai ô chưa có tác dụng.

## Proposed fix / Hướng xử lý
EN: Confirm destinations with Product, then route the events to the matching coordinators with the member name as context.
VI: Chốt đích đến với Product, rồi chuyển các event tới coordinator tương ứng kèm tên thành viên.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
