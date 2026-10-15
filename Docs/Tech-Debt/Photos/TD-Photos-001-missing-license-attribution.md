---
id: TD-Photos-001
title: Gallery photos are shown without author / license attribution
title_vi: Ảnh gallery hiển thị chưa kèm tác giả / giấy phép
feature: Photos
level: High
status: Open
created: 2026-10-06
updated: 2026-10-15
files:
  - InnerLamp/Presentation/Scenes/Photos/Views/ILPhotosPhotoCardView.swift
---

## Description / Mô tả
EN: Many gallery images are CC BY / CC BY-SA (Wikimedia Commons) and require attribution. The grid does not show author, license or source because those fields exist only on `GET /v1/gallery/{id}` and the screen has no detail view.
VI: Nhiều ảnh gallery là CC BY / CC BY-SA (Wikimedia Commons) và yêu cầu ghi công. Lưới ảnh chưa hiển thị tác giả, giấy phép, nguồn vì các trường này chỉ có ở `GET /v1/gallery/{id}` và màn hình chưa có màn chi tiết.

## Why it was taken on / Lý do chấp nhận nợ
EN: The task scope was the list integration; a detail screen is a separate feature.
VI: Phạm vi lần này là tích hợp danh sách; màn chi tiết là một tính năng riêng.

## Impact / Ảnh hưởng
EN: License non-compliance risk before release.
VI: Rủi ro vi phạm giấy phép trước khi phát hành.

## Proposed fix / Hướng xử lý
EN: Add a photo detail screen (tap a cell) calling `/v1/gallery/{id}` and showing author, license and a link to `source_url`.
VI: Thêm màn chi tiết ảnh (chạm vào ô) gọi `/v1/gallery/{id}` và hiển thị tác giả, giấy phép, liên kết `source_url`.

## Tracked by / Theo dõi tại
EN: The fix is planned in `Docs/Specs/Gallery/tasks.md` (Phases 2–4, product spec gallery v1.0); close this entry when it ships.
VI: Hướng sửa đã nằm trong `Docs/Specs/Gallery/tasks.md` (Phase 2–4, product spec gallery v1.0); đóng entry này khi phát hành.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
