---
id: TD-PhotoViewer-002
title: Viewer pages only through the photos loaded in the grid
title_vi: Viewer chỉ lật trong các ảnh đã tải ở lưới
feature: PhotoViewer
level: Low
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/Photos/ILPhotosCoordinator.swift:49
---

## Description / Mô tả
EN: The viewer receives a snapshot of the loaded list; reaching the last photo does not load the next gallery page, and the counter total is the loaded count, not the server total.
VI: Viewer nhận bản chụp danh sách đã tải; tới ảnh cuối không tải trang tiếp, và tổng ở bộ đếm là số đã tải, không phải tổng của server.

## Why it was taken on / Lý do chấp nhận nợ
EN: Keeps the viewer independent of the paging use case; not requested.
VI: Giữ viewer độc lập với use case phân trang; chưa có yêu cầu.

## Impact / Ảnh hưởng
EN: A user can't swipe past the loaded photos (up to 20 per page) without going back.
VI: Người dùng không lật quá số ảnh đã tải (20 ảnh/trang) nếu chưa quay lại lưới.

## Proposed fix / Hướng xử lý
EN: Feed the viewer the grid's `ILPhotosViewModel` state stream and trigger load-more near the end.
VI: Cho viewer theo dõi state của `ILPhotosViewModel` và gọi load-more khi gần cuối.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
