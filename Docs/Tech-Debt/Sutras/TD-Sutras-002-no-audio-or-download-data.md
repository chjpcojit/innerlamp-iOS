---
id: TD-Sutras-002
title: List cards never show the "downloaded" badge (audio badge now follows `audio_url`)
title_vi: Thẻ danh sách không bao giờ hiện nhãn "đã tải" (nhãn "có audio" nay theo `audio_url`)
feature: Sutras
level: Low
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/Sutras/ILSutrasViewModel.swift
---

## Description / Mô tả
EN: Update 2026-10-07: the backend now returns `audio_url` (`""` = no audio), and `hasAudio` follows it — but no sutra has audio yet, so the badge still never shows in practice. `isDownloaded` stays hard-wired to `false` because the app has no download feature yet.
VI: Cập nhật 2026-10-07: BE đã trả `audio_url` (`""` = không có audio) và `hasAudio` đã theo trường này — nhưng hiện chưa kinh nào có audio nên nhãn vẫn chưa hiện. `isDownloaded` vẫn gán cứng `false` vì app chưa có tính năng tải về.

## Why it was taken on / Lý do chấp nhận nợ
EN: Product decision (2026-10-07): leave this part unhandled and record the debt.
VI: Quyết định của product (2026-10-07): chưa xử lý phần này, ghi lại nợ kỹ thuật.

## Impact / Ảnh hưởng
EN: No offline indicator in the list. (The duration used to be hidden for `duration_minutes: null`; the server now fills every sutra.)
VI: Danh sách không có chỉ báo offline. (Thời lượng từng bị ẩn khi `duration_minutes: null`; nay server đã điền cho mọi kinh.)

## Proposed fix / Hướng xử lý
EN: When the Downloads feature lands, carry the downloaded flag through `ILSutraEntity` → `ILSutrasItemModel`.
VI: Khi tính năng Downloads hoàn thành, truyền cờ đã tải qua `ILSutraEntity` → `ILSutrasItemModel`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
