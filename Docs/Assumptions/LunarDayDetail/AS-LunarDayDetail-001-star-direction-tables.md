---
id: AS-LunarDayDetail-001
title: Hỷ/Tài/Hạc thần direction tables follow one printed source
title_vi: Bảng hướng Hỷ/Tài/Hạc thần theo một nguồn in duy nhất
feature: LunarDayDetail
level: Medium
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Core/Utils/ILLunarCalendar.swift:356
source: "1001 Kiêng Kỵ Trong Tín Ngưỡng Dân Gian" (Thanh Hóa, 2010)
owner: Product / BA
---

## Assumption / Giả định
EN: Tài thần (by day Thiên Can: Giáp/Ất Đông Nam, Bính/Đinh Đông, Mậu Bắc, Kỷ Nam, Canh/Tân Tây Nam, Nhâm Tây, Quý Tây Bắc) and the 60-day Hạc thần table follow the source above. Hỷ thần matches the widely used Can-pair rule. Almanac sources disagree on Tài thần (one news article lists Đinh → Tây, Kỷ → Bắc), and no second independent reference was verified.
VI: Tài thần (theo Thiên Can ngày) và bảng Hạc thần 60 ngày theo nguồn trên. Hỷ thần khớp quy tắc cặp Can phổ biến. Các nguồn lịch không thống nhất về Tài thần (một bài báo ghi Đinh → Tây, Kỷ → Bắc); chưa có nguồn độc lập thứ hai được kiểm chứng.

## Rationale / Cơ sở giả định
EN: Tài thần was already aligned to this source on 2026-09-27; changing it without a confirmed reference would swap one unverified table for another.
VI: Tài thần đã được chỉnh theo nguồn này ngày 2026-09-27; đổi khi chưa có nguồn xác nhận chỉ là thay bảng chưa kiểm chứng này bằng bảng khác.

## Implications if wrong / Hệ quả nếu sai
EN: Users would see a wrong wealth/avoid direction on some days; fix is a table edit in `ILLunarCalendar` plus tests.
VI: Người dùng thấy sai hướng Tài thần/Hạc thần ở một số ngày; sửa bằng chỉnh bảng trong `ILLunarCalendar` và test.

## Validation / Cách xác nhận
EN: Product/BA confirms the reference table (or a second printed almanac) for Tài thần and Hạc thần.
VI: Product/BA xác nhận bảng tham chiếu (hoặc một cuốn lịch in thứ hai) cho Tài thần và Hạc thần.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated)_
VI: _(điền khi Validated/Invalidated)_
