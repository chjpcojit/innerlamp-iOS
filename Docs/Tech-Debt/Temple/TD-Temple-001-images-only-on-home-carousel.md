---
id: TD-Temple-001
title: Temple photos are shown only on the Home carousel
title_vi: Ảnh chùa mới chỉ hiển thị ở carousel Trang chủ
feature: Temple
level: Low
status: Open
created: 2026-10-06
updated: 2026-10-06
files:
  - InnerLamp/Presentation/Scenes/Home/Views/ILHomeTempleCarouselView.swift
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILRemoteImageView.swift
---

## Description / Mô tả
EN: Only the Home "Chùa Việt Nam" carousel loads `thumbnail_url`. Other temple surfaces (Temple page hero, TempleFinder, Sangha rows) still use gradients / placeholders even though `image_url` is available. Also, `ILRemoteImageView` has no disk cache of its own and decodes full-size images (no downsampling).
VI: Chỉ carousel "Chùa Việt Nam" ở Trang chủ tải `thumbnail_url`. Các màn khác (hero Trang chùa, TempleFinder, hàng Sangha) vẫn dùng gradient / placeholder dù đã có `image_url`. `ILRemoteImageView` cũng chưa có cache đĩa riêng và giải mã ảnh kích thước đầy đủ (chưa downsample).

## Why it was taken on / Lý do chấp nhận nợ
EN: Scope was limited to the one surface that already reserves an image area; other screens need design decisions.
VI: Phạm vi giới hạn ở màn duy nhất đã có sẵn vùng ảnh; các màn khác cần quyết định thiết kế.

## Impact / Ảnh hưởng
EN: Inconsistent imagery across temple screens; full images (~1 MB) would be heavy if used in lists.
VI: Hình ảnh không đồng nhất giữa các màn chùa; ảnh full (~1 MB) sẽ nặng nếu dùng trong danh sách.

## Proposed fix / Hướng xử lý
EN: Reuse `ILRemoteImageView` (thumb in lists, full in the hero) once designs are confirmed; add downsampling if memory grows.
VI: Dùng lại `ILRemoteImageView` (thumb cho danh sách, full cho hero) sau khi chốt thiết kế; thêm downsample nếu bộ nhớ tăng.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
