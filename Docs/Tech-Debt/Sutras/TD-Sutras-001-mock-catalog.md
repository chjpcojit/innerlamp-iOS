---
id: TD-Sutras-001
title: Sutra catalog is hardcoded mock data
title_vi: Danh mục kinh đang là dữ liệu mock cứng
feature: Sutras
level: Medium
status: Resolved
created: 2026-10-03
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/Sutras/ILSutrasUseCase.swift:57
---

## Description / Mô tả
EN: The 11 sutras come from a static list in the UseCase (strings in `vi.json`), mirroring the prototype's `SUTRA_CAT`. Only `sutra.phapcu` has a real detail page.
VI: 11 bộ kinh lấy từ danh sách tĩnh trong UseCase (chuỗi trong `vi.json`), theo `SUTRA_CAT` của prototype. Chỉ `sutra.phapcu` có trang chi tiết thật.

## Why it was taken on / Lý do chấp nhận nợ
EN: No confirmed catalog API contract.
VI: Chưa có hợp đồng API danh mục kinh.

## Impact / Ảnh hưởng
EN: Users see sutras whose detail/reader content is missing; no real download/audio state.
VI: Người dùng thấy các bộ kinh chưa có nội dung chi tiết; trạng thái tải/audio là giả.

## Proposed fix / Hướng xử lý
EN: Add `ILSutrasRepository` + DTO/Mapper once the API is confirmed; replace `makeCatalog()`.
VI: Thêm `ILSutrasRepository` + DTO/Mapper khi API được xác nhận; thay `makeCatalog()`.

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-07 — the list now reads `GET /v1/sutras` through `ILSutraRepository` (BE API confirmed by the [BE]-InnerLamp session). The mock catalog is gone.
VI: Đã xử lý 2026-10-07 — danh sách đọc `GET /v1/sutras` qua `ILSutraRepository` (BE đã xác nhận API). Catalog mock đã bị xoá.
