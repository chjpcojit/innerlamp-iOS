---
id: AS-MeritBook-003
title: Empty history shows a note; absent letter and project blocks are hidden
title_vi: Lịch sử trống hiện ghi chú; thư và dự án vắng mặt thì ẩn khối
feature: MeritBook
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/MeritBook/Views/ILMeritHistoryCardView.swift:55
  - InnerLamp/Presentation/Scenes/MeritBook/ILMeritBookViewController.swift:198
source: Docs/Specs/MeritBook/SRS.md (FR-003, FR-004, FR-006, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype only shows the populated state. We assume: empty history → a short note "Chưa có lần cúng dường nào."; no letter or no project → the whole block (title + card) is hidden; failure → the shared error state.
VI: Prototype chỉ có trạng thái có dữ liệu. Giả định: lịch sử trống → ghi chú "Chưa có lần cúng dường nào."; không có thư hoặc dự án → ẩn cả khối (tiêu đề + thẻ); lỗi → trạng thái lỗi dùng chung.

## Rationale / Cơ sở giả định
EN: Needed to avoid blank cards; mirrors how the monthly block handles "off".
VI: Cần để không có thẻ trống; giống cách khối hộ trì xử lý trạng thái "tắt".

## Implications if wrong / Hệ quả nếu sai
EN: Copy/layout tweaks only.
VI: Chỉ chỉnh nội dung/bố cục.

## Validation / Cách xác nhận
EN: Design review of empty/error states.
VI: Design review các trạng thái trống/lỗi.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
