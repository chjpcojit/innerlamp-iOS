---
id: TD-FamilyTreeChronicle-001
title: save(_:) persists nothing — chronicle edits and clan-head changes are lost on relaunch
title_vi: save(_:) không lưu gì — phả ký và việc đổi tộc trưởng mất khi mở lại app
feature: FamilyTreeChronicle
level: High
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTreeChronicle/ILFamilyTreeChronicleUseCase.swift
---

## Description / Mô tả
EN: The UseCase `save(_:)` is a one-line `print("TODO: ...")` stub; the updated books only live in the family-tree ViewModel until the app closes.
VI: `save(_:)` trong UseCase chỉ là stub `print("TODO: ...")` một dòng; các gia phả đã cập nhật chỉ tồn tại trong ViewModel của màn cây gia phả cho đến khi tắt app.

## Why it was taken on / Lý do chấp nhận nợ
EN: No confirmed API contract or local store for the clan book (same as TD-FamilyTree-001, TD-FamilyTreeAddMember-001).
VI: Chưa có hợp đồng API hay kho lưu cục bộ cho gia phả (giống TD-FamilyTree-001, TD-FamilyTreeAddMember-001).

## Impact / Ảnh hưởng
EN: Everything written in Phả ký disappears on relaunch.
VI: Mọi nội dung đã ghi trong Phả ký biến mất khi mở lại app.

## Proposed fix / Hướng xử lý
EN: Once a Repository exists, use data-builder: DTO + mapper + repository, replace the stub body and mock the Repository in the tests.
VI: Khi có Repository, dùng data-builder: DTO + mapper + repository, thay thân stub và mock Repository trong test.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
