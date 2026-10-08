---
id: AS-LunarDayDetail-002
title: The calendar image belongs on the Lunar Day Detail hero
title_vi: Ảnh lịch âm hiển thị ở hero màn Chi tiết ngày âm
feature: LunarDayDetail
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/LunarDayDetail/Views/ILLunarDayDetailHeroView.swift
source: Chat request 2026-10-07 ("hiển thị ở trang ngày âm"), Docs/Specs/LunarDayDetail/requirements.md (hero imagery ⚠️)
owner: Product
---

## Assumption / Giả định
EN: "Trang ngày âm" means the Lunar Day Detail screen (not the LunarCalendar month screen). The image of `GET /v1/calendar/image?date=…` is shown as the background of its hero.
VI: "Trang ngày âm" là màn Chi tiết ngày âm (không phải màn lịch tháng LunarCalendar). Ảnh của `GET /v1/calendar/image?date=…` làm nền hero của màn này.

## Rationale / Cơ sở giả định
EN: The endpoint is per solar date and the day-detail screen receives exactly one solar `Date`; its hero already had a pending real-image slot (gradient placeholder). The month screen shows 6 months at once, so one picture does not fit.
VI: Endpoint theo ngày dương và màn chi tiết nhận đúng 1 `Date` dương; hero của nó sẵn có chỗ chờ ảnh thật (đang là gradient). Màn lịch tháng hiển thị 6 tháng cùng lúc nên 1 ảnh không phù hợp.

## Implications if wrong / Hệ quả nếu sai
EN: The image would need to move (or be added) to the LunarCalendar day-info card; the Data/Domain layers built here are reusable as-is.
VI: Ảnh phải chuyển (hoặc thêm) sang thẻ thông tin ngày của LunarCalendar; phần Data/Domain đã làm dùng lại nguyên vẹn.

## Validation / Cách xác nhận
EN: Ask the product owner / check the build on a device.
VI: Hỏi product owner / xem bản build trên thiết bị.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
