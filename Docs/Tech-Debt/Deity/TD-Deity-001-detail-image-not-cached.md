---
id: TD-Deity-001
title: Deity detail hero image URL is not persisted in the Core Data cache
title_vi: URL ảnh hero của chi tiết Phật & Bồ Tát chưa được lưu vào cache Core Data
feature: Deity
level: Low
status: Open
created: 2026-10-06
updated: 2026-10-06
files:
  - InnerLamp/Data/DataSources/Local/ILDeityLocalDataSource.swift:198
  - InnerLamp/Presentation/Scenes/Deity/Views/ILDeityHeroView.swift
---

## Description / Mô tả
EN: `ILDeityEntity.imageURL` is filled from the remote DTO, but `ILDeityMO` has no image column, so a detail read from the offline cache has `imageURL == nil` and the hero shows the watermark placeholder.
VI: `ILDeityEntity.imageURL` lấy từ DTO remote, nhưng `ILDeityMO` chưa có cột ảnh nên chi tiết đọc từ cache offline có `imageURL == nil` và hero hiện placeholder chữ Hán.

## Why it was taken on / Lý do chấp nhận nợ
EN: Adding a column needs a Core Data model migration; out of scope for the header-image request.
VI: Thêm cột cần migrate model Core Data; ngoài phạm vi yêu cầu thêm ảnh header.

## Impact / Ảnh hưởng
EN: Offline-only detail views lack the hero image (remote images are not available offline anyway unless HTTP-cached).
VI: Xem chi tiết khi offline không có ảnh hero (ảnh remote vốn cũng cần mạng trừ khi đã có HTTP cache).

## Proposed fix / Hướng xử lý
EN: Add `imageUrl` to `ILDeityMO` (lightweight migration) and map it in `makeEntity`.
VI: Thêm `imageUrl` vào `ILDeityMO` (lightweight migration) và map trong `makeEntity`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
