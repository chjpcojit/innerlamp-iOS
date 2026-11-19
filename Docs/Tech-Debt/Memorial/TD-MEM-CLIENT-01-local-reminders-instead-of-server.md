---
id: TD-MEM-CLIENT-01
title: Memorial reminders run locally instead of on the server
title_vi: Nhắc giỗ chạy local thay vì do server gửi
feature: Memorial
level: High
status: Open
created: 2026-11-16
updated: 2026-11-16
files:
  - InnerLamp/Data/Services/ILLocalMemorialReminderScheduler.swift
  - InnerLamp/Domain/Reminders/ILMemorialReminderScheduling.swift
  - InnerLamp/App/DIContainer.swift
---

## Description / Mô tả
EN: iOS schedules memorial reminders with `UNUserNotificationCenter` because backend Phase 8–10 (server planning, push, inbox) does not exist yet. The account setting is still saved on the server; delivery is not.
VI: iOS đặt nhắc giỗ bằng `UNUserNotificationCenter` vì BE chưa có Phase 8–10 (lập kế hoạch, push, inbox). Cấu hình nhắc vẫn lưu trên server; việc gửi thì không.

## Why it was taken on / Lý do chấp nhận nợ
EN: Product FR-MEM-008 and BR-MEM-13 expect one server-driven reminder per giỗ across devices. Waiting for Phase 10 would ship no reminder at all; local delivery was chosen for the interim (technical decision D1).
VI: Product FR-MEM-008 và BR-MEM-13 yêu cầu một nhắc do server gửi cho mỗi kỳ giỗ trên mọi thiết bị. Chờ Phase 10 thì chưa có nhắc nào; giao tạm bằng local (quyết định D1).

## Impact / Ảnh hưởng
EN: Changing an entry on another device or on the web does not update this device until the app opens again. Two devices produce two reminders. A reinstall loses the schedule until the next open.
VI: Sửa mục trên thiết bị khác hoặc trên web không cập nhật máy này cho tới lần mở app sau. Hai thiết bị bắn hai nhắc. Cài lại app mất lịch tới lần mở kế tiếp.

## Proposed fix / Hướng xử lý
EN: Pay when all four D1 conditions hold: contract v4.0 deployed, Phase 9 planning deployed, Phase 10 + notification feature deployed, and a client release has staged the cutover. Then switch the one DI line to `ILNoopMemorialReminderScheduler`, call `cancelAll()` once on first launch, keep the server-driven UI.
VI: Trả nợ khi đủ 4 điều kiện D1: contract v4.0 đã deploy, Phase 9 đã deploy, Phase 10 + feature notification đã deploy, và đã có bản client staged cutover. Khi đó đổi một dòng DI sang `ILNoopMemorialReminderScheduler`, gọi `cancelAll()` một lần ở lần mở đầu, giữ UI đọc từ server.

## Owner and repayment condition / Chủ nợ và điều kiện trả
EN: Owner ⚔ Đạo Sư ⚔. Condition: All four D1 conditions (technical-decisions.md, D1).
VI: Chủ nợ ⚔ Đạo Sư ⚔. Điều kiện: Đủ 4 điều kiện D1 (technical-decisions.md, D1).

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
