---
id: TD-Photos-002
title: Home "Ảnh chùa đẹp" strip still uses static placeholders
title_vi: Dải "Ảnh chùa đẹp" ở Home vẫn dùng dữ liệu tĩnh
feature: Photos
level: Medium
status: Resolved
created: 2026-10-06
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/Home/ILHomeUseCase.swift
---

## Description / Mô tả
EN: Home builds `ILHomePhotoEntity(id: "pg-N")` locally while the Photos screen now shows real images; the backend offers `GET /v1/gallery/top` (10 images) for this strip.
VI: Home dựng `ILHomePhotoEntity(id: "pg-N")` cục bộ trong khi màn Photos đã dùng ảnh thật; BE có `GET /v1/gallery/top` (10 ảnh) cho dải này.

## Why it was taken on / Lý do chấp nhận nợ
EN: Out of scope for the Photos list integration.
VI: Ngoài phạm vi tích hợp danh sách Photos.

## Impact / Ảnh hưởng
EN: Home and Photos look inconsistent.
VI: Home và Photos hiển thị không đồng nhất.

## Proposed fix / Hướng xử lý
EN: Load `/v1/gallery/top` in the Home use case through `ILPhotosRepository` and render with `ILRemoteImageView`.
VI: Gọi `/v1/gallery/top` trong Home use case qua `ILPhotosRepository` và hiển thị bằng `ILRemoteImageView`.

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-07 — Home loads `/v1/gallery/top` through `ILPhotosRepository.loadTopPhotos()` (not committed yet).
VI: Đã xử lý 2026-10-07 — Home gọi `/v1/gallery/top` qua `ILPhotosRepository.loadTopPhotos()` (chưa commit).
