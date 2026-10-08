---
id: TD-FamilyTreeAddMember-001
title: save(_:) persists nothing — added members are lost on relaunch
title_vi: save(_:) không lưu gì — người vừa thêm mất khi mở lại app
feature: FamilyTreeAddMember
level: High
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTreeAddMember/ILFamilyTreeAddMemberUseCase.swift
---

## Description / Mô tả
EN: The UseCase `save(_:)` is a one-line `print("TODO: ...")` stub; the updated tree only exists in the family-tree ViewModel until the app closes.
VI: `save(_:)` trong UseCase chỉ là stub `print("TODO: ...")` một dòng; cây đã cập nhật chỉ tồn tại trong ViewModel của màn cây gia phả cho đến khi tắt app.

## Why it was taken on / Lý do chấp nhận nợ
EN: No confirmed API contract or local store for the clan book (same as TD-FamilyTreeCreate-001 and TD-FamilyTree-001).
VI: Chưa có hợp đồng API hay kho lưu cục bộ cho gia phả (giống TD-FamilyTreeCreate-001 và TD-FamilyTree-001).

## Impact / Ảnh hưởng
EN: Added people disappear on relaunch.
VI: Người đã thêm biến mất khi mở lại app.

## Proposed fix / Hướng xử lý
EN: Once a Repository exists, use il-data-layer-builder: DTO + mapper + repository, then replace the stub body and mock the Repository in the tests.
VI: Khi có Repository, dùng il-data-layer-builder: DTO + mapper + repository, rồi thay thân stub và mock Repository trong test.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
