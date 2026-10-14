---
id: TD-Home-003
title: Events carousel is network-only (no offline cache)
title_vi: Carousel sự kiện chỉ dùng mạng (không có cache offline)
feature: Home
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/Repositories/ILCalendarEventRepositoryImpl.swift
  - InnerLamp/Presentation/Scenes/Home/ILHomeViewModel.swift:336
---

## Description / Mô tả
EN: `ILCalendarEventRepositoryImpl` has no local cache. When the server is unreachable (or the user is not signed in, the endpoint needs a token) the Home events carousel is empty. The previous local Core Data catalogue worked offline.
VI: `ILCalendarEventRepositoryImpl` không có cache cục bộ. Khi không tới được server (hoặc chưa đăng nhập, endpoint cần token) carousel sự kiện trống. Catalog Core Data trước đây dùng được offline.

## Why it was taken on / Lý do chấp nhận nợ
EN: First integration, scoped to Home; the contract allows caching per year (`Cache-Control: private, max-age`) but a cache model was not requested yet.
VI: Tích hợp lần đầu, giới hạn ở Home; contract cho phép cache theo năm nhưng chưa có yêu cầu mô hình cache.

## Impact / Ảnh hưởng
EN: Offline users see no events on Home (a regression versus the seeded catalogue); the carousel fails silently.
VI: Người dùng offline không thấy sự kiện trên Trang chủ (lùi so với catalog seed); carousel lỗi âm thầm.

## Proposed fix / Hướng xử lý
EN: Cache the year's response in Core Data (or fall back to `ILBuddhistEventUseCase` while offline), as the temple/deity catalogues do.
VI: Cache response theo năm trong Core Data (hoặc rơi về `ILBuddhistEventUseCase` khi offline), như catalog chùa/Phật.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
