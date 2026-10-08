---
id: TD-Reader-001
title: Chanting highlight is timer-driven, no real audio
title_vi: Highlight tụng chạy bằng timer, chưa có audio thật
feature: Reader
level: Medium
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Reader/ILReaderUseCase.swift:50
  - InnerLamp/Presentation/Scenes/Reader/ILReaderViewModel.swift:84
---

## Description / Mô tả
EN: The current line advances every 2.6 s (scaled by 1x/1.2x/1.5x) on a timer; no recitation audio plays and position/duration are derived from the line index.
VI: Dòng đang tụng tự chuyển mỗi 2,6 giây (nhân theo 1x/1.2x/1.5x) bằng timer; không phát audio tụng, vị trí/thời lượng suy từ chỉ số dòng.

## Why it was taken on / Lý do chấp nhận nợ
EN: No recitation files or audio API exist yet; the prototype uses the same simulation.
VI: Chưa có file/API audio tụng; prototype cũng mô phỏng như vậy.

## Impact / Ảnh hưởng
EN: Highlight can drift from a real recording; the −10s/+10s buttons move 2 lines, not 10 seconds.
VI: Highlight sẽ lệch với bản thu thật; nút −10s/+10s nhảy 2 dòng chứ không phải 10 giây.

## Proposed fix / Hướng xử lý
EN: Wire a real player (`ILPracticeSoundPlayer`/AVAudioPlayer) with per-line timestamps from the API.
VI: Nối player thật (`ILPracticeSoundPlayer`/AVAudioPlayer) với mốc thời gian từng dòng từ API.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
