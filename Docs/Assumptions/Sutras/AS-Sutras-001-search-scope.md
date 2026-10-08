---
id: AS-Sutras-001
title: Search matches name and original name only
title_vi: Tìm kiếm chỉ khớp tên và nguyên ngữ
feature: Sutras
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/Sutras/ILSutrasViewModel.swift
source: design handoff prototype `sutraVals()` (also searches description and tag text)
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype also searches the description and tags; the app sends `q` and the server searches titles (any language) + collection + reference across the whole catalog (the API has no description). Updated 2026-10-07 (was client-side on loaded pages).
VI: Prototype còn tìm theo mô tả và thẻ; app gửi `q` và server tìm theo tên (mọi ngôn ngữ) + bộ kinh + số hiệu trên toàn bộ danh mục (API không có mô tả). Cập nhật 2026-10-07 (trước đây lọc client trên các trang đã tải).

## Rationale / Cơ sở giả định
EN: Keeps the mock small; descriptions arrive with the real API.
VI: Giữ mock gọn; mô tả sẽ có cùng API thật.

## Implications if wrong / Hệ quả nếu sai
EN: Some keyword searches (e.g. "Quán Thế Âm") return fewer results than the prototype.
VI: Một số từ khóa (vd. "Quán Thế Âm") ra ít kết quả hơn prototype.

## Validation / Cách xác nhận
EN: Confirm with product when the catalog API is defined.
VI: Xác nhận với product khi định nghĩa API danh mục.

## Outcome / Kết luận
EN: _(fill in)_
VI: _(điền khi có kết luận)_
