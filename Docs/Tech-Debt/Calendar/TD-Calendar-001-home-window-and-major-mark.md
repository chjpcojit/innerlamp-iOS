---
id: TD-Calendar-001
title: Home six-month window, empty month card and major mark UI not built
title_vi: Chưa làm cửa sổ 6 tháng ở Home, thẻ tháng trống và dấu "lễ lớn" trên UI
feature: Calendar
level: Medium
status: Open
created: 2026-10-17
updated: 2026-10-17
files:
  - InnerLamp/Domain/UseCases/Home/ILHomeUseCase.swift
  - InnerLamp/Presentation/Scenes/Festivals/ILFestivalsViewModel.swift
---

## Description / Mô tả
EN: Contract 2.2.0 is read and the data rules are applied (public route, Buddhist-only Home, tiers by
`is_major` / `recurrence`, "Lễ lớn" chip on `is_major`, no local Rằm / Mùng 1). Not done: BR-CAL-15's
six-month window across the year end (with per-year failure + retry), the card for a month without
Buddhist occurrences, the major mark and group names on rows and detail, hiding empty detail sections.
`festivals.observance.*` strings are now unused.
VI: Đã đọc contract 2.2.0 và áp dụng các quy tắc dữ liệu. Chưa làm: cửa sổ 6 tháng qua năm mới,
thẻ tháng trống, dấu lễ lớn / tên nhóm trên dòng và chi tiết, ẩn mục rỗng ở chi tiết. Các chuỗi
`festivals.observance.*` hiện không còn dùng.

## Why it was taken on / Lý do chấp nhận nợ
EN: Those items need UI and copy decisions (Phase 4 and 8 of the Calendar tasks); this change was the contract integration.
VI: Các mục này cần quyết định UI và nội dung (Phase 4 và 8); lần này chỉ tích hợp contract.

## Impact / Ảnh hưởng
EN: Home still shows January–December of the current year; late in the year it shows past months and no next-year months.
VI: Home vẫn hiển thị tháng 1–12 của năm hiện tại; cuối năm không thấy các tháng của năm sau.

## Proposed fix / Hướng xử lý
EN: Calendar tasks Phase 4/6 via `ui-builder`.
VI: Làm Phase 4/6 của Calendar qua `ui-builder`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
