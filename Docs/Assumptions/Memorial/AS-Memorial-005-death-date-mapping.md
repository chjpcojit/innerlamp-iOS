---
id: AS-Memorial-005
title: A known death year is sent as a solar death_date; a lunar entry is converted both ways
title_vi: Năm mất đã biết được gửi dạng death_date dương lịch; mục âm lịch được quy đổi hai chiều
feature: Memorial
level: Medium
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Data/DTOs/Mappers/ILMemorialMapper.swift
source: Backend openapi.yaml `/v1/memorials` (docs/specs/api/openapi.yaml in the backend repo)
owner: Product / Backend
---

## Assumption / Giả định
EN: The entity keeps `day`/`month` in `calendarKind` plus a `deathYear` that is a lunar year for lunar entries. The API wants `death_date` as a solar date when the year is known, so the app converts lunar -> solar on save and solar -> lunar on load. A lunar day 30 in a 29-day month resolves to day 29 (the `lunarToSolar` rule), so it reads back as 29. A leap-month result on load keeps its day/month (leap flag dropped). A solar date that does not exist (31 Apr, 29 Feb in a non-leap year) is rejected locally as `invalidInput`; the form limits the day list per month to prevent most of these. A death date later than today is rejected by the server (`VALIDATION_ERROR`).
VI: Thực thể giữ `day`/`month` theo `calendarKind` cùng `deathYear` (là năm âm với mục âm lịch). API cần `death_date` dương lịch khi biết năm, nên app đổi âm -> dương khi lưu và dương -> âm khi tải. Ngày 30 âm của tháng 29 ngày được quy về 29 (quy tắc `lunarToSolar`) nên đọc lại là 29. Kết quả rơi vào tháng nhuận khi tải vẫn giữ ngày/tháng (bỏ cờ nhuận). Ngày dương không tồn tại (31/4, 29/2 năm không nhuận) bị từ chối ngay tại app (`invalidInput`); form giới hạn danh sách ngày theo tháng để tránh phần lớn trường hợp này. Ngày mất sau hôm nay bị server từ chối (`VALIDATION_ERROR`).

## Rationale / Cơ sở giả định
EN: The API contract defines `death_date` as solar and tells the app to convert; the app already tracks lunar years for the ordinal ("giỗ đầu/hết").
VI: Hợp đồng API định nghĩa `death_date` là dương lịch và yêu cầu app tự quy đổi; app đã dùng năm âm để tính lần giỗ ("giỗ đầu/hết").

## Implications if wrong / Hệ quả nếu sai
EN: Entries entered in the leap month or on a day-30 of a short month could shift by a day or lose the leap flag after a round trip; the ordinal could be off by one near the lunar new year.
VI: Mục nhập ở tháng nhuận hoặc ngày 30 của tháng thiếu có thể lệch một ngày hoặc mất cờ nhuận sau khi lưu rồi tải lại; số lần giỗ có thể lệch 1 gần Tết.

## Validation / Cách xác nhận
EN: Ask Product whether leap-month giỗ must be supported (the API has `death_leap_month` for the no-year form); try on a device with a day-30 entry.
VI: Hỏi Product có cần hỗ trợ giỗ tháng nhuận không (API có `death_leap_month` cho dạng không biết năm); thử trên thiết bị với mục ngày 30.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
