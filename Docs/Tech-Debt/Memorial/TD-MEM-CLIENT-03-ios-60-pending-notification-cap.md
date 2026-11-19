---
id: TD-MEM-CLIENT-03
title: iOS schedules at most 60 pending memorial notifications
title_vi: iOS chỉ đặt tối đa 60 nhắc giỗ chờ
feature: Memorial
level: Medium
status: Open
created: 2026-11-16
updated: 2026-11-16
files:
  - InnerLamp/Domain/Memorial/ILMemorialReminderPlanner.swift
  - InnerLamp/Data/Services/ILLocalMemorialReminderScheduler.swift
---

## Description / Mô tả
EN: iOS keeps at most 64 pending notifications per app. Per AC MEM-RMD-08 the memorial plan is capped at 60 entries, one pending notification each (nearest giỗ first), and re-planned on every app open.
VI: iOS giữ tối đa 64 notification chờ mỗi app. Theo AC MEM-RMD-08, kế hoạch sổ giỗ giới hạn 60 mục, mỗi mục một nhắc chờ (kỳ giỗ gần nhất trước), và đặt lại mỗi lần mở app.

## Why it was taken on / Lý do chấp nhận nợ
EN: Leaving no headroom would crowd out other app notifications; the cap is below the system limit on purpose (technical decision D1).
VI: Không để dư chỗ sẽ lấn các notification khác của app; mức trần cố ý thấp hơn giới hạn hệ thống (quyết định D1).

## Impact / Ảnh hưởng
EN: A book with more than 60 entries that all have reminders schedules only the 60 nearest entries; farther entries are planned when the app next opens. After a reminder fires, the next app open schedules the following giỗ.
VI: Sổ có hơn 60 mục đều bật nhắc chỉ đặt 60 mục gần nhất; các mục xa hơn được đặt ở lần mở app kế tiếp. Sau khi một nhắc bắn, lần mở app kế tiếp đặt kỳ giỗ sau.

## Proposed fix / Hướng xử lý
EN: Pay when server push exists: the server schedules all entries and the app schedules none.
VI: Trả nợ khi có server push: server lập lịch mọi mục, app không đặt gì.

## Owner and repayment condition / Chủ nợ và điều kiện trả
EN: Owner ✦ Nguyên Anh ✦. Condition: Server push (Phase 10).
VI: Chủ nợ ✦ Nguyên Anh ✦. Điều kiện: Có server push (Phase 10).

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
