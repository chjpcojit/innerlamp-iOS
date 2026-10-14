---
id: AS-Temples-001
title: Region chips are Tất cả / Bắc / Trung / Nam (no Tây Nguyên)
title_vi: Chip miền gồm Tất cả / Bắc / Trung / Nam (không có Tây Nguyên)
feature: Temples
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Temples/ILTemplesViewModel.swift
source: Docs/innerlamp-project/ prototype screen `temples` (5 chips incl. "Tây Nguyên")
owner: Product / BA
---

## Assumption / Giả định
EN: The screen reuses TempleFinder's 4 region chips. The server `region` enum only knows north/central/south (others arrive as `.other(raw)`), so a "Tây Nguyên" chip cannot filter reliably.
VI: Màn dùng lại 4 chip miền của TempleFinder. Enum `region` của server chỉ có Bắc/Trung/Nam (giá trị khác là `.other(raw)`) nên chip "Tây Nguyên" chưa lọc được đáng tin cậy.

## Rationale / Cơ sở giả định
EN: Consistency with the existing screen and the API contract.
VI: Nhất quán với màn hiện có và hợp đồng API.

## Implications if wrong / Hệ quả nếu sai
EN: Highland temples only show under "Tất cả".
VI: Chùa Tây Nguyên chỉ hiện ở "Tất cả".

## Validation / Cách xác nhận
EN: Ask backend whether `region` will include a highlands value.
VI: Hỏi backend có thêm giá trị Tây Nguyên cho `region` không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
