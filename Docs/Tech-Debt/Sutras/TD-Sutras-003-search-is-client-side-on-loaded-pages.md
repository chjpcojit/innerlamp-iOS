---
id: TD-Sutras-003
title: Search only filters the pages already loaded
title_vi: Tìm kiếm chỉ lọc trên các trang đã tải
feature: Sutras
level: Medium
status: Resolved
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/Sutras/ILSutrasViewModel.swift
---

## Description / Mô tả
EN: The backend ignores `q` (no text search). The search box therefore filters, client-side and diacritic-insensitively, only the sutras already loaded (20 per page, 153 in total). A sutra on a page the user has not scrolled to yet cannot be found.
VI: BE bỏ qua tham số `q` (chưa có tìm kiếm chữ). Ô tìm kiếm vì vậy chỉ lọc phía client, không phân biệt dấu, trên các bản kinh đã tải (20 mục/trang, tổng 153). Bản kinh ở trang chưa cuộn tới sẽ không tìm thấy.

## Why it was taken on / Lý do chấp nhận nợ
EN: Product decision (2026-10-07): "search can be done later".
VI: Quyết định của product (2026-10-07): "phần tìm kiếm có thể làm sau".

## Impact / Ảnh hưởng
EN: Incomplete search results until all pages are loaded; the "N bản kinh phù hợp" count only covers loaded rows.
VI: Kết quả tìm kiếm thiếu cho tới khi tải hết các trang; số "N bản kinh phù hợp" chỉ tính các dòng đã tải.

## Proposed fix / Hướng xử lý
EN: Ask the backend for a real `q` search, then send it as a server filter (restart from page 1) and drop `search(_:query:)`.
VI: Đề nghị BE làm tìm kiếm `q` thật, rồi gửi như bộ lọc server (bắt đầu lại từ trang 1) và bỏ `search(_:query:)`.

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-07 — backend added `q` to `GET /v1/sutras`; the app sends it as a debounced server filter and `search(_:query:)` was removed. Not yet committed.
VI: Đã xử lý 2026-10-07 — BE đã thêm `q` cho `GET /v1/sutras`; app gửi như bộ lọc server (debounce) và đã bỏ `search(_:query:)`. Chưa commit.
