---
id: AS-Home-002
title: Home lunar hero card shows the calendar image of the selected day
title_vi: Thẻ âm lịch lớn ở Home hiển thị ảnh lịch của ngày đang chọn
feature: Home
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/Home/ILHomeViewModel.swift
  - InnerLamp/Presentation/Scenes/Home/Views/ILHomeLunarHeroCardView.swift
source: Verbal request ("integrate the lunar calendar image into the Home lunar-date area"); no spec/design handoff for the layout
owner: Product / Design
---

## Assumption / Giả định
EN: The picture (`GET /v1/calendar/image?date=`) fills the whole Home lunar hero card behind the text, follows the day selected in the week strip (one request per day per screen), is covered by a `sunk2` scrim (alpha .55→.88) for legibility, and shows the author/license credit line under the verse. Offline/error keeps the gradient card with no error.
VI: Ảnh phủ kín thẻ âm lịch lớn ở Home phía sau chữ, đổi theo ngày chọn ở dải lịch tuần (mỗi ngày gọi 1 lần/màn), có lớp phủ `sunk2` (alpha .55→.88) cho chữ đọc được, dòng ghi công tác giả/giấy phép nằm dưới câu kinh. Offline/lỗi giữ thẻ gradient, không báo lỗi.

## Rationale / Cơ sở giả định
EN: Mirrors the LunarDayDetail hero (AS-LunarDayDetail-002); the old card comment already reserved an image slot behind the overlay.
VI: Giống hero của LunarDayDetail (AS-LunarDayDetail-002); card cũ đã chừa chỗ cho ảnh dưới lớp overlay.

## Implications if wrong / Hệ quả nếu sai
EN: Layout/scrim opacity needs rework in one view; if the image should be today-only, drop the per-day loading.
VI: Phải chỉnh bố cục/độ mờ lớp phủ ở một view; nếu chỉ cần ảnh của hôm nay thì bỏ phần tải theo ngày.

## Validation / Cách xác nhận
EN: Product/Design to review on a physical device in light and dark mode (text legibility over real photos).
VI: Product/Design xem trên thiết bị thật ở light/dark (độ đọc của chữ trên ảnh thật).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated)_
VI: _(điền khi Validated/Invalidated)_
