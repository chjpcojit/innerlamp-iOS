---
id: TD-MEM-CLIENT-02
title: The website stores the reminder setting but cannot deliver a reminder
title_vi: Website lưu cấu hình nhắc nhưng không gửi được nhắc
feature: Memorial
level: Medium
status: Open
created: 2026-11-16
updated: 2026-11-16
files:
  - Docs/Specs/Memorial/client-contract.md
---

## Description / Mô tả
EN: The web client has no local notification path. It shows the reminder setting and the `Có nhắc` tag, but a user who lives on the web receives no reminder until the notification list exists.
VI: Web không có đường gửi nhắc local. Web hiện cấu hình nhắc và nhãn `Có nhắc`, nhưng người dùng chỉ dùng web không nhận được nhắc cho tới khi có notification list.

## Why it was taken on / Lý do chấp nhận nợ
EN: Web Push needs VAPID, a service worker and backend support that Phase 10 has not shipped; product §3.6 says web sees reminders only in the notification list (technical decision D2).
VI: Web Push cần VAPID, service worker và backend hỗ trợ — Phase 10 chưa có; product §3.6 nói web chỉ thấy nhắc trong notification list (quyết định D2).

## Impact / Ảnh hưởng
EN: FR-MEM-008 is not met on web. A web-only user must open the book to see the next giỗ.
VI: FR-MEM-008 chưa đạt trên web. Người chỉ dùng web phải mở sổ để xem kỳ giỗ tới.

## Proposed fix / Hướng xử lý
EN: Add the notification list API and a web inbox; the setting stays account-wide, so no client change is needed beyond reading the list.
VI: Bổ sung API notification list và inbox trên web; cấu hình thuộc tài khoản nên không phải đổi thêm ngoài việc đọc danh sách.

## Owner and repayment condition / Chủ nợ và điều kiện trả
EN: Owner ⚔ Đạo Sư ⚔. Condition: Notification list available on web.
VI: Chủ nợ ⚔ Đạo Sư ⚔. Điều kiện: Có notification list trên web.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
