---
id: TD-SutraDetail-002
title: Detail screen has no audio, reading progress or per-section duration
title_vi: Màn chi tiết chưa có audio, tiến trình đọc và thời lượng từng phẩm
feature: SutraDetail
level: Low
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/SutraDetail/ILSutraDetailViewModel.swift
---

## Description / Mô tả
EN: `GET /v1/sutras/{id}` has no audio, narrator, cover image, reading progress or per-section duration. The ViewModel therefore sets `hasAudio = false` (CTA "Đọc kinh", no round play button), never shows the progress card, shows no download badge, and leaves each table-of-contents row's duration empty. The "Tải về máy" button is still a TODO in the coordinator.
VI: `GET /v1/sutras/{id}` không có audio, người tụng, ảnh bìa, tiến trình đọc hay thời lượng từng phẩm. Vì vậy ViewModel đặt `hasAudio = false` (CTA "Đọc kinh", ẩn nút phát tròn), không bao giờ hiện thẻ tiến trình, không có nhãn tải về, và để trống thời lượng từng dòng Mục lục. Nút "Tải về máy" vẫn là TODO ở coordinator.

## Why it was taken on / Lý do chấp nhận nợ
EN: Product decision (2026-10-07): leave this part unhandled and record the debt.
VI: Quyết định của product (2026-10-07): chưa xử lý phần này, ghi lại nợ kỹ thuật.

## Impact / Ảnh hưởng
EN: The progress card, play button and per-row durations of the design are never visible. Most sutras have `sections: []`, so the table of contents is hidden for them.
VI: Thẻ tiến trình, nút phát và thời lượng từng dòng của thiết kế không bao giờ hiện. Đa số kinh có `sections: []` nên Mục lục bị ẩn.

## Proposed fix / Hướng xử lý
EN: Extend the entity when the backend adds audio / progress; build per-user progress (`readingProgress`) locally or via an API.
VI: Mở rộng entity khi BE bổ sung audio / tiến trình; làm tiến trình đọc theo người dùng (`readingProgress`) ở local hoặc qua API.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
