---
id: TD-FamilyTree-009
title: Residence, burial place, dharma name and tablet temple have no data source
title_vi: Nơi sống, nơi an táng, pháp danh và chùa thờ bài vị chưa có nguồn dữ liệu
feature: FamilyTree
level: Medium
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeStateModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeDetailSheetView.swift
---

## Description / Mô tả
EN: `ILFamilyTreeDetailModel` carries `residence`, `burialPlace`, `dharmaName` and `tabletTemple`, but `ILFamilyMemberEntity` has no such fields, so the ViewModel always passes `nil` and the sheet shows "Chưa cập nhật".
VI: `ILFamilyTreeDetailModel` có `residence`, `burialPlace`, `dharmaName`, `tabletTemple`, nhưng `ILFamilyMemberEntity` chưa có các trường này nên ViewModel luôn truyền `nil` và sheet hiện "Chưa cập nhật".

## Why it was taken on / Lý do chấp nhận nợ
EN: Source/API fields are unconfirmed (⚠️ Not confirmed in requirements v2.0); adding entity fields without a contract would be a guess.
VI: Trường nguồn/API chưa xác nhận (⚠️ Not confirmed trong requirements v2.0); thêm trường vào entity khi chưa có hợp đồng API là đoán mò.

## Impact / Ảnh hưởng
EN: Four rows always read "Chưa cập nhật".
VI: Bốn dòng luôn hiện "Chưa cập nhật".

## Proposed fix / Hướng xử lý
EN: When the API contract exists: add the fields to `ILFamilyMemberEntity`/DTO, map them in `makeDetail`, and add tests.
VI: Khi có hợp đồng API: thêm trường vào `ILFamilyMemberEntity`/DTO, map trong `makeDetail` và bổ sung test.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
