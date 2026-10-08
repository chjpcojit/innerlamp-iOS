---
id: TD-Memorial-001
title: Reminder scheduling and the Reminders sync are stubs
title_vi: Đặt lịch nhắc và đồng bộ Lời nhắc mới chỉ là stub
feature: Memorial
level: High
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Memorial/ILMemorialUseCase.swift:128
  - InnerLamp/Domain/UseCases/Memorial/ILMemorialUseCase.swift:132
---

## Description / Mô tả
EN: `scheduleReminders(for:)` and `cancelReminder(forEntryID:)` only print a TODO line. A user can switch the reminder on and save, but no notification is ever scheduled and nothing is added to Reminders.
VI: `scheduleReminders(for:)` và `cancelReminder(forEntryID:)` chỉ in một dòng TODO. Người dùng có thể bật nhắc và lưu, nhưng không có thông báo nào được đặt lịch và không có gì được thêm vào Lời nhắc.

## Why it was taken on / Lý do chấp nhận nợ
EN: The reminder mechanism is not confirmed (see `AS-Memorial-002`), and the codebase has no notification or EventKit infrastructure; the skill rules also forbid guessing an I/O implementation.
VI: Cơ chế nhắc chưa được xác nhận (xem `AS-Memorial-002`), codebase chưa có hạ tầng thông báo hay EventKit; quy tắc của skill cũng cấm đoán mò phần triển khai I/O.

## Impact / Ảnh hưởng
EN: User-facing: the screen promises reminders ("Nhắc trước ngày giỗ", the saved-message mentions Lời nhắc) that never fire. Entries are stored with their reminder fields, so no data migration is needed later.
VI: Người dùng thấy rõ: màn hình hứa nhắc ("Nhắc trước ngày giỗ", thông báo lưu nhắc tới Lời nhắc) nhưng không bao giờ nhắc. Mục đã lưu kèm trường nhắc nên sau này không cần migrate dữ liệu.

## Proposed fix / Hướng xử lý
EN: Confirm the mechanism, then add a reminder-scheduler protocol (UNUserNotificationCenter, next occurrence only, reschedule on list load; EventKit behind the sync switch if wanted) with permission handling and tests. Tracked in `Docs/Specs/Memorial/tasks.md` Phase 2.
VI: Xác nhận cơ chế, sau đó thêm protocol đặt lịch nhắc (UNUserNotificationCenter, chỉ kỳ tới, đặt lại khi tải danh sách; EventKit sau công tắc đồng bộ nếu cần) kèm xử lý quyền và test. Theo dõi ở `Docs/Specs/Memorial/tasks.md` Phase 2.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
