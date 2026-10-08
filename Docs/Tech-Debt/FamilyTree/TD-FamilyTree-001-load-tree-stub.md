---
id: TD-FamilyTree-001
title: loadTrees() has no data source and returns no books
title_vi: loadTrees() chưa có nguồn dữ liệu và trả về không có gia phả nào
feature: FamilyTree
level: High
status: Open
created: 2026-10-03
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTree/ILFamilyTreeUseCase.swift:24
---

## Description / Mô tả
EN: `ILFamilyTreeUseCaseImpl.loadTrees()` (was `loadTree()` before the multi-book change of 2026-10-04) prints a TODO and returns no books (see also TD-FamilyTree-011), so the screen always shows its empty state in the app. All behaviour (layout, selection, search, sheet) is implemented and unit-tested against the design's 24-person sample, but no real clan data reaches it.
VI: `ILFamilyTreeUseCaseImpl.loadTrees()` (trước 2026-10-04 là `loadTree()`) chỉ in TODO và trả về không có gia phả nào (xem thêm TD-FamilyTree-011), nên màn hình luôn hiện trạng thái rỗng trong app. Toàn bộ hành vi (bố cục, chọn người, tìm kiếm, sheet) đã làm và có test với mẫu 24 người của design, nhưng chưa có dữ liệu dòng họ thật.

## Why it was taken on / Lý do chấp nhận nợ
EN: No API contract or local storage model for the clan book exists, and il-screen-builder forbids guessing network/Repository code or inventing data.
VI: Chưa có API contract hay mô hình lưu trữ cục bộ cho gia phả, và il-screen-builder cấm đoán code network/Repository hoặc tự bịa dữ liệu.

## Impact / Ảnh hưởng
EN: The feature is not usable end to end; users see "Chưa có gia phả".
VI: Tính năng chưa dùng được từ đầu đến cuối; người dùng thấy "Chưa có gia phả".

## Proposed fix / Hướng xử lý
EN: Confirm the source (API or Core Data like Memorial), add `ILFamilyTreeRepository` (Domain) + implementation, DTO + Mapper if an API, inject it into `ILFamilyTreeUseCaseImpl`, and replace the stub body.
VI: Chốt nguồn dữ liệu (API hoặc Core Data như Memorial), thêm `ILFamilyTreeRepository` (Domain) + bản cài đặt, DTO + Mapper nếu dùng API, inject vào `ILFamilyTreeUseCaseImpl` và thay thân hàm stub.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
