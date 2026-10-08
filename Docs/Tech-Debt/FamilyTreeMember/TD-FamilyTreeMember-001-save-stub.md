---
id: TD-FamilyTreeMember-001
title: save(_:) persists nothing — edited members are lost on relaunch
title_vi: save(_:) không lưu gì — thông tin đã sửa mất khi mở lại app
feature: FamilyTreeMember
level: High
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTreeMember/ILFamilyTreeMemberUseCase.swift
---

## Description / Mô tả
EN: The UseCase `save(_:)` is a one-line `print("TODO: ...")` stub; the edited tree only lives in the family-tree ViewModel until the app closes.
VI: `save(_:)` trong UseCase chỉ là stub `print("TODO: ...")` một dòng; cây đã sửa chỉ tồn tại trong ViewModel của màn cây gia phả cho đến khi tắt app.

## Why it was taken on / Lý do chấp nhận nợ
EN: No confirmed API contract or local store for the clan book (same as TD-FamilyTreeAddMember-001, TD-FamilyTree-001).
VI: Chưa có hợp đồng API hay kho lưu cục bộ cho gia phả (giống TD-FamilyTreeAddMember-001, TD-FamilyTree-001).

## Impact / Ảnh hưởng
EN: Edits to a person disappear on relaunch.
VI: Thông tin đã sửa của một người biến mất khi mở lại app.

## Proposed fix / Hướng xử lý
EN: Once a Repository exists, use il-data-layer-builder: DTO + mapper + repository, then replace the stub body and mock the Repository in the tests.
VI: Khi có Repository, dùng il-data-layer-builder: DTO + mapper + repository, rồi thay thân stub và mock Repository trong test.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
