---
id: AS-PhotoViewer-001
title: The viewer frames every photo at 4:3, full width
title_vi: Viewer khung mọi ảnh theo tỉ lệ 4:3, full chiều ngang
feature: PhotoViewer
level: Low
status: Validated
created: 2026-10-07
updated: 2026-10-15
files:
  - InnerLamp/Presentation/Scenes/PhotoViewer/ILPhotoViewerViewController.swift:19
source: Docs/Assumptions/Photos/AS-Photos-001-fixed-4-3-tile-ratio.md
owner: Product / BA
---

## Assumption / Giả định
EN: The image frame is 4:3 aspect-fill, like the grid tile, because the API returns no image size. Portrait photos are cropped.
VI: Khung ảnh là 4:3 aspect-fill như ô ở lưới vì API không trả kích thước ảnh. Ảnh dọc sẽ bị cắt.

## Rationale / Cơ sở giả định
EN: The prototype's hero uses the tile's ratio, and a matching frame makes the hero morph undistorted.
VI: Hero trong prototype dùng tỉ lệ của ô, khung giống nhau giúp hiệu ứng bay không méo.

## Implications if wrong / Hệ quả nếu sai
EN: Cropped subjects in tall photos; fix by adding width/height to the API and sizing the frame from them.
VI: Chủ thể ảnh dọc bị cắt; sửa bằng cách API trả width/height rồi dựng khung theo đó.

## Validation / Cách xác nhận
EN: Ask backend for image dimensions; check on device with portrait photos.
VI: Hỏi backend về kích thước ảnh; kiểm tra trên thiết bị với ảnh dọc.

## Outcome / Kết luận
EN: Validated 2026-10-15 — product spec gallery v1.0 BR-GAL-05 confirms uniform 4:3 tiles and viewer frame (anh Đức, be#35). Now covered by `Docs/Specs/Gallery/`.
VI: Đã xác nhận 2026-10-15 — product spec gallery v1.0 BR-GAL-05 chốt ô ảnh và khung viewer đồng nhất 4:3 (anh Đức, be#35). Nay thuộc `Docs/Specs/Gallery/`.
