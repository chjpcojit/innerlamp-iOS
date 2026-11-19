---
id: TD-MEM-CLIENT-04
title: Android WorkManager reminders can be delayed by Doze
title_vi: Nhắc WorkManager trên Android có thể trễ vì Doze
feature: Memorial
level: Medium
status: Open
created: 2026-11-16
updated: 2026-11-16
files:
  - Docs/Specs/Memorial/client-contract.md
---

## Description / Mô tả
EN: The Android interim path uses one-time WorkManager work with `initialDelay`; the app does not request `SCHEDULE_EXACT_ALARM`.
VI: Đường tạm trên Android dùng WorkManager one-time với `initialDelay`; app không xin `SCHEDULE_EXACT_ALARM`.

## Why it was taken on / Lý do chấp nhận nợ
EN: Exact alarms need a user-granted special permission and draw Play policy scrutiny; a few minutes of delay is acceptable for a giỗ reminder (technical decision D1).
VI: Exact alarm cần quyền đặc biệt người dùng cấp và bị Play policy soi; trễ vài phút chấp nhận được với nhắc giỗ (quyết định D1).

## Impact / Ảnh hưởng
EN: Doze can delay a reminder by minutes and, in deep idle, longer. It never fires at the wrong date.
VI: Doze có thể làm nhắc trễ vài phút, vào idle sâu có thể lâu hơn. Không bắn sai ngày.

## Proposed fix / Hướng xử lý
EN: Pay with server push, or with an approved exact-alarm exemption if the product owner accepts the Play review cost.
VI: Trả nợ bằng server push, hoặc xin miễn trừ exact alarm nếu chủ sản phẩm chấp nhận chi phí review Play.

## Owner and repayment condition / Chủ nợ và điều kiện trả
EN: Owner ✦ Hóa Thần ✦. Condition: Server push, or an approved exact-alarm decision.
VI: Chủ nợ ✦ Hóa Thần ✦. Điều kiện: Có server push, hoặc quyết định exact alarm được duyệt.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
