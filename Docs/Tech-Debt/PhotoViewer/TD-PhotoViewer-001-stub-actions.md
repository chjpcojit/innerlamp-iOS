---
id: TD-PhotoViewer-001
title: Save / Set wallpaper / Share and favorites are stubs
title_vi: Lưu ảnh / Đặt hình nền / Chia sẻ và yêu thích mới là stub
feature: PhotoViewer
level: High
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/PhotoViewer/ILPhotoViewerViewModel.swift:100
---

## Description / Mô tả
EN: The three actions only show the prototype's confirmation toast ("Đã lưu vào thư viện ảnh"...) and print a TODO; nothing is saved, set or shared. Favorites live in memory for the session.
VI: Ba nút chỉ hiện toast xác nhận như prototype và in TODO; chưa lưu, đặt hay chia sẻ gì. Yêu thích chỉ nằm trong bộ nhớ trong phiên.

## Why it was taken on / Lý do chấp nhận nợ
EN: User chose "stub everything like the prototype" to land the UI first.
VI: Người dùng chọn "stub toàn bộ giống prototype" để làm UI trước.

## Impact / Ảnh hưởng
EN: The toasts claim success that did not happen — misleading if shipped.
VI: Toast báo thành công dù chưa làm gì — gây hiểu nhầm nếu phát hành.

## Proposed fix / Hướng xử lý
EN: Save via `PHPhotoLibrary` (add-only permission), share via `UIActivityViewController` (iOS cannot set the wallpaper programmatically — replace or remove that action), persist favorites locally.
VI: Lưu bằng `PHPhotoLibrary` (quyền chỉ thêm), chia sẻ bằng `UIActivityViewController` (iOS không đặt hình nền bằng code — đổi hoặc bỏ nút này), lưu yêu thích cục bộ.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
