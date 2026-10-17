---
id: AS-Calendar-001
title: Rate-limited message copy and no automatic retry
title_vi: Nội dung thông báo bị giới hạn lượt gọi và không tự thử lại
feature: Calendar
level: Low
status: Unvalidated
created: 2026-10-17
updated: 2026-10-17
files:
  - InnerLamp/Domain/Repositories/ILCatalogError.swift
  - InnerLamp/Resources/Localization/vi.json
source: Docs/Specs/Calendar/requirements.md (criterion 22, ⚠️ copy not given by product)
owner: Product / BA
---

## Assumption / Giả định
EN: `429 RATE_LIMITED` from `GET /v1/calendar/events` is shown as the generic load failure with the
text "Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút." (`catalog.error.rateLimited`). The app does
not retry on its own and ignores `retry_after_seconds` in the UI (it is carried on the error only).
VI: `429 RATE_LIMITED` của `GET /v1/calendar/events` hiển thị như lỗi tải thông thường với câu trên;
app không tự thử lại và chưa dùng `retry_after_seconds` trên UI (chỉ giữ trong error).

## Rationale / Cơ sở giả định
EN: The backend asks clients to cache per year and handle 429 with a "try later" notice; product
spec v1.2 gives no copy.
VI: Backend yêu cầu cache theo năm và báo "thử lại sau" khi 429; product spec v1.2 chưa có nội dung.

## Implications if wrong / Hệ quả nếu sai
EN: Only the wording changes; no logic depends on it.
VI: Chỉ đổi câu chữ; không logic nào phụ thuộc.

## Validation / Cách xác nhận
EN: Product supplies the final copy (tasks.md Phase 8).
VI: Product cung cấp nội dung chính thức (tasks.md Phase 8).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
