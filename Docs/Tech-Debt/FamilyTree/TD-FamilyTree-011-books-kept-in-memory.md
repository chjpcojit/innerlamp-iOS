---
id: TD-FamilyTree-011
title: The user's clan books live only in memory
title_vi: Các gia phả của người dùng chỉ nằm trong bộ nhớ
feature: FamilyTree
level: High
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Domain/UseCases/FamilyTree/ILFamilyTreeUseCase.swift:25
---

## Description / Mô tả
EN: `ILFamilyTreeViewModel` keeps every book in `books` and `loadTrees()` is a one-line TODO stub that returns no books. Books created in the app (and edits to people, chronicle and hometown) vanish when the app closes.
VI: `ILFamilyTreeViewModel` giữ mọi gia phả trong `books` và `loadTrees()` chỉ là một dòng TODO trả về không có gia phả nào. Gia phả tạo trong app (và các chỉnh sửa người, phả ký, quê gốc) mất khi đóng app.

## Why it was taken on / Lý do chấp nhận nợ
EN: There is no confirmed API contract or local Repository for clan books; il-screen-builder must not invent one.
VI: Chưa có API hay Repository cục bộ đã xác nhận cho gia phả; il-screen-builder không được tự bịa.

## Impact / Ảnh hưởng
EN: Users lose everything they enter. Two books are enough for the switcher and the merged view to be exercised, but nothing is shared between devices or members.
VI: Người dùng mất toàn bộ dữ liệu đã nhập. Hai gia phả đủ để thử menu chọn và view gộp, nhưng không chia sẻ được giữa thiết bị hay thành viên.

## Proposed fix / Hướng xử lý
EN: Agree the API / Core Data model for books (ids, side, chronicle), then run il-data-layer-builder to replace `loadTrees()` and the three `save` stubs (create, add member, member, chronicle).
VI: Chốt API / mô hình Core Data cho gia phả (id, bên nội/ngoại, phả ký), rồi chạy il-data-layer-builder để thay `loadTrees()` và các stub `save` (tạo, thêm người, hồ sơ, phả ký).

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
