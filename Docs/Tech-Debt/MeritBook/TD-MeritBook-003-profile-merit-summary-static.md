---
id: TD-MeritBook-003
title: Profile merit card summary is not derived from the merit book
title_vi: Tóm tắt trên thẻ công đức ở Hồ sơ không lấy từ Sổ công đức
feature: MeritBook
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Profile/ILProfileViewModel.swift
---

## Description / Mô tả
EN: The Profile card says "N lần cúng dường · M ngọn đèn Vu Lan" from the profile mock; the merit book shows different sample figures.
VI: Thẻ ở Hồ sơ hiện "N lần cúng dường · M ngọn đèn Vu Lan" từ mock của profile; Sổ công đức hiện số liệu mẫu khác.

## Why it was taken on / Lý do chấp nhận nợ
EN: Both are sample data until a real API exists.
VI: Cả hai đều là dữ liệu mẫu cho tới khi có API thật.

## Impact / Ảnh hưởng
EN: Inconsistent numbers between the two screens.
VI: Số liệu không khớp giữa hai màn.

## Proposed fix / Hướng xử lý
EN: Feed the Profile summary from the same merit-book source when the API exists.
VI: Lấy tóm tắt ở Hồ sơ từ cùng nguồn Sổ công đức khi có API.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
