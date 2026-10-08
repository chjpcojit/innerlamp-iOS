---
id: TD-Memorial-002
title: Portrait is a placeholder avatar — no photo picker or storage
title_vi: Ảnh chân dung chỉ là avatar tạm — chưa có chọn ảnh và lưu trữ
feature: Memorial
level: Medium
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Memorial/ILMemorialEditViewController.swift:60
  - InnerLamp/Presentation/Scenes/Memorial/Views/ILMemorialHighlightCardView.swift
  - InnerLamp/Presentation/Scenes/Memorial/Views/ILMemorialRowView.swift
---

## Description / Mô tả
EN: The form shows a 104pt avatar with the name's first letter and cannot be tapped; the highlight card and rows do the same. `ILMemorialEntity.portraitFileName` and the Core Data attribute exist but are never set.
VI: Form hiện avatar 104pt với chữ cái đầu của tên và không chạm được; thẻ nổi bật và các hàng cũng vậy. `ILMemorialEntity.portraitFileName` và thuộc tính Core Data đã có nhưng không bao giờ được gán.

## Why it was taken on / Lý do chấp nhận nợ
EN: Portrait source and storage are not confirmed (PHPicker vs camera, file in the app container vs server upload) and need a photo-library permission decision.
VI: Nguồn và nơi lưu ảnh chưa được xác nhận (PHPicker hay camera, file trong app container hay tải lên server) và cần quyết định về quyền thư viện ảnh.

## Impact / Ảnh hưởng
EN: The prototype's "Chạm hoặc kéo ảnh chân dung vào" caption is intentionally not shown so the UI does not promise a feature that is not there.
VI: Dòng chữ "Chạm hoặc kéo ảnh chân dung vào" của prototype cố ý không hiển thị để UI không hứa một tính năng chưa có.

## Proposed fix / Hướng xử lý
EN: Confirm the source/storage, add a picker (PHPicker needs no permission string) and a small file store keyed by `portraitFileName`, then replace the avatar in the three views with a portrait view. Tracked in `Docs/Specs/Memorial/tasks.md` Phase 2.
VI: Xác nhận nguồn/nơi lưu, thêm bộ chọn ảnh (PHPicker không cần chuỗi xin quyền) và kho file nhỏ theo `portraitFileName`, rồi thay avatar ở ba view bằng view chân dung. Theo dõi ở `Docs/Specs/Memorial/tasks.md` Phase 2.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
