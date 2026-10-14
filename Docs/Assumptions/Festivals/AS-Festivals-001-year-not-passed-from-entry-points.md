---
id: AS-Festivals-001
title: Festivals screen always starts at the current year; entry points do not pass a year
title_vi: Màn Lịch lễ luôn bắt đầu từ năm hiện tại; các nơi mở màn không truyền năm
feature: Festivals
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Festivals/ILFestivalsViewModel.swift
  - InnerLamp/Domain/UseCases/Festivals/ILFestivalsUseCase.swift
source: User request 2026-10-11 (Home "Xem tất cả" → load current year Jan–Dec, scroll loads next year)
owner: Product / BA
---

## Assumption / Giả định
EN: Home, Sangha and Deity all open the Festivals screen without parameters. The screen loads the current year (Jan–Dec) and appends the next year when scrolling near the bottom; loading stops at 2200 (limit of `ILLunarCalendar` accuracy). Earlier years are not reachable. A failed "next year" load keeps the list and retries on the next scroll without any error UI.
VI: Trang chủ, Sangha và Deity đều mở màn Lịch lễ không truyền tham số. Màn tải năm hiện tại (tháng 1–12) và nối năm kế tiếp khi cuộn gần cuối; dừng ở năm 2200 (giới hạn độ chính xác của `ILLunarCalendar`). Không xem được các năm trước. Tải năm kế tiếp lỗi thì giữ danh sách và thử lại ở lần cuộn sau, không hiện UI lỗi.

## Rationale / Cơ sở giả định
EN: The request only asked for "current year, then next year on scroll"; every entry point wants "today onward", so a parameter would be unused.
VI: Yêu cầu chỉ nêu "năm hiện tại, cuộn xuống tải năm sau"; mọi nơi mở màn đều muốn xem từ hiện tại nên tham số năm sẽ không được dùng.

## Implications if wrong / Hệ quả nếu sai
EN: If an entry point must open a specific year (e.g. from a calendar date), add a `year` argument to the coordinator and ViewModel; if users must see past years, add upward loading.
VI: Nếu một nơi mở màn cần mở đúng năm khác (vd từ một ngày trên lịch), thêm tham số `year` cho coordinator/ViewModel; nếu cần xem năm trước, thêm tải theo chiều ngược lên.

## Validation / Cách xác nhận
EN: Confirm with Product that no entry point needs a specific year and that silent retry is acceptable.
VI: Xác nhận với Product rằng không nơi nào cần mở năm cụ thể và việc im lặng thử lại là chấp nhận được.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
