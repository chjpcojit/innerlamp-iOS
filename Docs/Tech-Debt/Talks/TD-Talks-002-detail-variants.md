---
id: TD-Talks-002
title: Video/text talks and 7 of 8 rows open the single audio Talk screen
title_vi: Bài video/văn bản và 7/8 dòng đều mở màn Pháp thoại audio duy nhất
feature: Talks
level: Medium
status: Open
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Domain/UseCases/Talks/ILTalksUseCase.swift:46
  - InnerLamp/Domain/UseCases/Talk/ILTalkUseCase.swift:41
---

## Description / Mô tả
EN: The design routes by type to `talk` / `talkYt` / `talkText`, each with its own content. The app only has the audio screen with one sample talk, which unknown ids fall back to.
VI: Design điều hướng theo loại tới `talk` / `talkYt` / `talkText`, mỗi màn có nội dung riêng. App chỉ có màn audio với 1 bài mẫu, id lạ fallback về bài đó.

## Why it was taken on / Lý do chấp nhận nợ
EN: Detail variants are a separate feature (Talk spec); the list task only covers the list screen.
VI: Các biến thể chi tiết là feature riêng (spec Talk); task này chỉ làm màn danh sách.

## Impact / Ảnh hưởng
EN: Tapping any row except the first shows the wrong talk.
VI: Chạm dòng nào ngoài dòng đầu cũng hiện sai bài.

## Proposed fix / Hướng xử lý
EN: Extend the Talk feature with YouTube and text variants and a per-id catalog; route by `mediaType` in `ILTalksCoordinator`.
VI: Mở rộng feature Talk với biến thể YouTube và văn bản cùng catalog theo id; điều hướng theo `mediaType` trong `ILTalksCoordinator`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
