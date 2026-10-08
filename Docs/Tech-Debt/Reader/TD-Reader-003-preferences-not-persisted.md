---
id: TD-Reader-003
title: Reader font size, background and auto-scroll are not persisted
title_vi: Cỡ chữ, màu nền, tự cuộn của Reader chưa được lưu
feature: Reader
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Reader/ILReaderViewModel.swift:58
---

## Description / Mô tả
EN: The three preferences live in memory and reset to defaults (size 20, default background, auto-scroll on) each time the screen opens. Settings has its own "Cỡ chữ kinh văn" that is not linked.
VI: Ba tùy chọn chỉ lưu trong bộ nhớ và về mặc định (cỡ 20, nền mặc định, tự cuộn bật) mỗi lần mở màn. Màn Cài đặt có "Cỡ chữ kinh văn" riêng chưa liên kết.

## Why it was taken on / Lý do chấp nhận nợ
EN: The prototype keeps them in transient state only; storage rules were not specified.
VI: Prototype chỉ giữ trong state tạm; chưa có quy tắc lưu trữ.

## Impact / Ảnh hưởng
EN: Users re-pick their reading setup every session.
VI: Người dùng phải chọn lại thiết lập đọc mỗi lần.

## Proposed fix / Hướng xử lý
EN: Store via `UserDefaultsService` and share the font-size key with Settings.
VI: Lưu qua `UserDefaultsService` và dùng chung khóa cỡ chữ với Cài đặt.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
