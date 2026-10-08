---
id: TD-FamilyTreeCreate-001
title: save(_:) persists nothing — a created tree is lost on relaunch
title_vi: save(_:) không lưu gì — gia phả vừa tạo mất khi mở lại app
feature: FamilyTreeCreate
level: High
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTreeCreate/ILFamilyTreeCreateUseCase.swift:118
---

## Description / Mô tả
EN: `ILFamilyTreeCreateUseCaseImpl.save(_:)` only prints a TODO. After "Tạo gia phả" the new tree is handed to the family tree screen in memory (`ILFamilyTreeViewModel.showCreatedTree`), but nothing is stored, and `loadTree()` still returns an empty tree (`TD-FamilyTree-001`), so the next launch shows the empty state again.
VI: `ILFamilyTreeCreateUseCaseImpl.save(_:)` chỉ in TODO. Sau khi bấm "Tạo gia phả", cây mới được chuyển sang màn cây gia phả trong bộ nhớ (`ILFamilyTreeViewModel.showCreatedTree`) nhưng không được lưu, và `loadTree()` vẫn trả cây rỗng (`TD-FamilyTree-001`), nên lần mở app sau lại thấy màn trống.

## Why it was taken on / Lý do chấp nhận nợ
EN: No API contract or local storage model for the clan book exists, and il-screen-builder forbids guessing network/Repository code.
VI: Chưa có API contract hay mô hình lưu trữ cục bộ cho gia phả, và il-screen-builder cấm đoán code network/Repository.

## Impact / Ảnh hưởng
EN: Users can create a tree and see it, but lose it on relaunch.
VI: Người dùng tạo và xem được cây nhưng mất khi mở lại app.

## Proposed fix / Hướng xử lý
EN: Fix together with `TD-FamilyTree-001`: one `ILFamilyTreeRepository` (Domain) used by both `loadTree()` and `save(_:)`, inject it into both UseCases, replace the stub body, and map save errors to a feature error.
VI: Xử lý cùng `TD-FamilyTree-001`: một `ILFamilyTreeRepository` (Domain) dùng cho cả `loadTree()` và `save(_:)`, inject vào cả hai UseCase, thay thân hàm stub và map lỗi lưu sang lỗi của feature.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
