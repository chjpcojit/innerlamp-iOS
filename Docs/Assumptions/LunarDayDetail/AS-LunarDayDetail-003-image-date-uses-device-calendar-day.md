---
id: AS-LunarDayDetail-003
title: The image date is the screen's solar date in the device time zone
title_vi: Ngày gửi lên API ảnh là ngày dương của màn hình theo múi giờ thiết bị
feature: LunarDayDetail
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Data/DTOs/Mappers/ILCalendarImageMapper.swift
source: Backend contract 2026-10-07 (date = solar YYYY-MM-DD; omitted = today in Asia/Ho_Chi_Minh)
owner: Backend / Product
---

## Assumption / Giả định
EN: `date` is built from the Gregorian day/month/year of the screen's `Date` in the device's current time zone — the same components the lunar computation uses — so the picture always matches the displayed day.
VI: `date` được dựng từ ngày/tháng/năm Gregorian của `Date` của màn hình theo múi giờ hiện tại của thiết bị — cùng thành phần mà phần tính âm lịch dùng — nên ảnh luôn khớp ngày đang hiển thị.

## Rationale / Cơ sở giả định
EN: The server cycles images by the date string only, so any consistent date string works; matching the displayed day is the least surprising.
VI: Server đổi ảnh chỉ theo chuỗi ngày, nên chuỗi ngày nhất quán là đủ; khớp ngày đang hiển thị là ít gây bất ngờ nhất.

## Implications if wrong / Hệ quả nếu sai
EN: A user outside Vietnam could see a different picture than someone in Vietnam for the same displayed day only if the product wanted a global "image of the day" — functionally harmless.
VI: Chỉ khi product muốn "ảnh của ngày" thống nhất toàn cầu thì người dùng ngoài Việt Nam mới thấy khác — không ảnh hưởng chức năng.

## Validation / Cách xác nhận
EN: Confirm with product whether the picture must be identical worldwide for a given calendar day.
VI: Xác nhận với product xem ảnh có cần giống nhau trên toàn cầu cho cùng một ngày không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
