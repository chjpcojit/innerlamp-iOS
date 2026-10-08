---
id: AS-Memorial-002
title: Reminders are local notifications, rescheduled on every list load (not built yet)
title_vi: Nhắc nhở là thông báo cục bộ, đặt lại mỗi lần tải danh sách (chưa làm)
feature: Memorial
level: High
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Memorial/ILMemorialUseCase.swift:128
source: Docs/Specs/Memorial/requirements.md (Pending — reminder mechanism and reschedule policy, ⚠️ Not confirmed)
owner: Product
---

## Assumption / Giả định
EN: "Nhắc nhở" will be a local notification (UNUserNotificationCenter) for the next occurrence only, rescheduled each time the list loads because lunar dates move in the solar calendar. "Thêm vào Lời nhắc" (Apple Reminders via EventKit) is not assumed to be built. Today both are one-line TODO stubs: the reminder fields are stored but nothing is scheduled.
VI: "Nhắc nhở" sẽ là thông báo cục bộ (UNUserNotificationCenter) chỉ cho kỳ giỗ tới, đặt lại mỗi lần tải danh sách vì ngày âm dịch chuyển trong lịch dương. "Thêm vào Lời nhắc" (app Lời nhắc của Apple qua EventKit) chưa được giả định là sẽ làm. Hiện cả hai chỉ là stub TODO một dòng: trường nhắc được lưu nhưng chưa có gì được đặt lịch.

## Rationale / Cơ sở giả định
EN: The user chose local notification as the default and deferred the rest. The codebase has no notification or EventKit code yet, and no permission strings.
VI: Người dùng chọn thông báo cục bộ làm mặc định và hoãn phần còn lại. Codebase chưa có code thông báo hay EventKit, cũng chưa có chuỗi xin quyền.

## Implications if wrong / Hệ quả nếu sai
EN: Users who turn on a reminder get nothing until it is built — a user-facing gap. If "Lời nhắc" means an in-app list or EventKit, the sync switch changes meaning and needs an Info.plist permission string.
VI: Người dùng bật nhắc nhưng sẽ không nhận được gì cho tới khi làm xong — lỗ hổng nhìn thấy được. Nếu "Lời nhắc" là danh sách trong app hoặc EventKit, công tắc đồng bộ đổi ý nghĩa và cần chuỗi quyền trong Info.plist.

## Validation / Cách xác nhận
EN: Confirm the mechanism and the permission-denied behaviour with Product, then implement behind a protocol (`Docs/Specs/Memorial/tasks.md` Phase 2).
VI: Xác nhận cơ chế và hành vi khi bị từ chối quyền với Product, sau đó làm sau một protocol (`Docs/Specs/Memorial/tasks.md` Phase 2).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
