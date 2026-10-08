---
id: TD-Language-002
title: Chosen sutra font size is not read by Reader or Settings slider
title_vi: Cỡ chữ kinh văn đã chọn chưa được Reader và thanh trượt Cài đặt dùng
feature: Language
level: Low
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/Language/ILLanguageUseCase.swift:36
  - InnerLamp/Domain/UseCases/Settings/ILSettingsUseCase.swift:42
---

## Description / Mô tả
EN: The 4-preset font size is stored under `il_scripture_font_size`, but the Reader keeps its own `fontSizeIndex` and the Settings slider row still uses the mock `scriptureFontScale` (0.62).
VI: Cỡ chữ 4 mức được lưu ở `il_scripture_font_size`, nhưng Reader có `fontSizeIndex` riêng và thanh trượt trong Cài đặt vẫn dùng `scriptureFontScale` mock (0.62).

## Why it was taken on / Lý do chấp nhận nợ
EN: Request scope was the Language screen and the theme integration only.
VI: Phạm vi yêu cầu chỉ gồm màn Ngôn ngữ và tích hợp giao diện sáng/tối.

## Impact / Ảnh hưởng
EN: Changing the size on this screen only changes the preview and the Settings summary text.
VI: Đổi cỡ chữ ở màn này chỉ đổi phần xem trước và dòng tóm tắt ở Cài đặt.

## Proposed fix / Hướng xử lý
EN: Have Reader / SutraDetail default their size from the stored preset; reconcile or remove the duplicate Settings slider.
VI: Cho Reader / SutraDetail lấy cỡ mặc định từ preset đã lưu; thống nhất hoặc bỏ thanh trượt trùng trong Cài đặt.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
