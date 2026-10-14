---
id: TD-MeritBook-002
title: Header "Cúng dường" action has no destination
title_vi: Nút "Cúng dường" ở header chưa có đích đến
feature: MeritBook
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/MeritBook/ILMeritBookCoordinator.swift:39
---

## Description / Mô tả
EN: `.openDonate` is emitted but the coordinator does nothing (TODO).
VI: `.openDonate` được phát nhưng coordinator chưa làm gì (TODO).

## Why it was taken on / Lý do chấp nhận nợ
EN: The donation flow (`Offering`) is not built.
VI: Luồng cúng dường (`Offering`) chưa được xây.

## Impact / Ảnh hưởng
EN: A visible button that does nothing.
VI: Có nút hiển thị nhưng bấm không có phản hồi.

## Proposed fix / Hướng xử lý
EN: Wire to the donation coordinator once it exists.
VI: Nối tới coordinator cúng dường khi có.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
