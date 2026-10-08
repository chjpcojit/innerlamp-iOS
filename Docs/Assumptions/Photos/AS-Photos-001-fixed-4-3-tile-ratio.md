---
id: AS-Photos-001
title: Gallery tiles use a fixed 4:3 ratio
title_vi: Ô ảnh gallery dùng tỉ lệ cố định 4:3
feature: Photos
level: Low
status: Unvalidated
created: 2026-10-06
updated: 2026-10-06
files:
  - InnerLamp/Presentation/Scenes/Photos/Views/ILPhotosPhotoCardView.swift
source: Docs/Specs/Photos/design.md (API contract — no width/height in the response)
owner: Backend / Product
---

## Assumption / Giả định
EN: The gallery API returns no image width/height, so every tile is shown at a fixed 4:3 (landscape) ratio, aspect-fill.
VI: API gallery không trả width/height ảnh, nên mọi ô ảnh hiển thị theo tỉ lệ cố định 4:3 (ngang), cắt aspect-fill.

## Rationale / Cơ sở giả định
EN: 12 sampled thumbnails on 2026-10-06 were all landscape (500x281 to 500x466); thumbnails are 500 px wide JPEGs.
VI: 12 thumbnail lấy mẫu ngày 2026-10-06 đều là ảnh ngang (500x281 đến 500x466); thumbnail là JPEG rộng 500 px.

## Implications if wrong / Hệ quả nếu sai
EN: Portrait or very wide photos get cropped; no functional impact.
VI: Ảnh dọc hoặc quá rộng bị cắt; không ảnh hưởng chức năng.

## Validation / Cách xác nhận
EN: Ask the backend to add `width`/`height` to the gallery item, or review the full set of 86 photos on a device.
VI: Đề nghị BE thêm `width`/`height` vào item gallery, hoặc xem toàn bộ 86 ảnh trên thiết bị.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated)_
VI: _(điền khi Validated/Invalidated)_
