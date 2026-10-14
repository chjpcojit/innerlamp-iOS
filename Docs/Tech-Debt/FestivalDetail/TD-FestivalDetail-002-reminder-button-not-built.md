---
id: TD-FestivalDetail-002
title: "Nhắc tôi ngày này" reminder button not built
title_vi: Nút "Nhắc tôi ngày này" chưa làm
feature: FestivalDetail
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/FestivalDetail/ILFestivalDetailViewController.swift
---

## Description / Mô tả
EN: The prototype's bottom "Nhắc tôi ngày này" button (primary/ghost toggle + note) is not implemented.
VI: Nút "Nhắc tôi ngày này" cuối trang của prototype chưa được làm.

## Why it was taken on / Lý do chấp nhận nợ
EN: The product owner deferred it ("làm sau"); the app also has no local-notification layer yet (see `Docs/Specs/Reminder/`).
VI: Chủ sản phẩm yêu cầu làm sau; app cũng chưa có hạ tầng thông báo cục bộ (xem `Docs/Specs/Reminder/`).

## Impact / Ảnh hưởng
EN: Users cannot be reminded of a festival day from this screen.
VI: Người dùng chưa thể đặt nhắc ngày lễ từ màn này.

## Proposed fix / Hướng xử lý
EN: Build the notification service, then add the toggle button (6:00 reminder, "Đã đặt nhắc" ghost state) and persist the choice per event + date.
VI: Làm dịch vụ thông báo, rồi thêm nút bật/tắt (nhắc 6:00, trạng thái "Đã đặt nhắc") và lưu theo sự kiện + ngày.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
