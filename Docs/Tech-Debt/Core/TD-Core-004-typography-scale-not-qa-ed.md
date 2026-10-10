---
id: TD-Core-004
title: Typography moved to the new scale without per-screen QA
title_vi: Typography đã chuyển sang thang cỡ mới nhưng chưa rà từng màn
feature: Core
level: Medium
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Common/DesignSystem/Tokens/ILTypography.swift
---

## Description / Mô tả
EN: Display tokens were snapped to the prototype's Cormorant scale (18 / 22 / 28 / 32, big numerals 68 / 84) and reading tokens to Literata (16 body, 13 italic); call sites keep their old line-height multipliers and layout assumptions. Doc comments across the code base still say "Lora". Only weights 500/600/700 (+ 500 italic) of Cormorant and Regular/Italic of Literata are bundled (static Literata cut, no optical sizes).
VI: Token tiêu đề được đưa về thang Cormorant của prototype (18 / 22 / 28 / 32, số lớn 68 / 84) và token chữ đọc về Literata (16 thân bài, 13 nghiêng); nơi gọi vẫn giữ line-height và giả định layout cũ. Comment trong code vẫn ghi "Lora". Chỉ bundle Cormorant weight 500/600/700 (+ 500 italic) và Literata Regular/Italic (bản static, không có optical size).

## Why it was taken on / Lý do chấp nhận nợ
EN: The request was to switch every font at once; per-screen visual QA needs a device and was out of scope for a build-only verification.
VI: Yêu cầu là đổi toàn bộ font cùng lúc; rà từng màn cần thiết bị thật, ngoài phạm vi khi chỉ xác minh bằng build.

## Impact / Ảnh hưởng
EN: Some screens may show truncated, cramped or too-tall text where sizes grew (e.g. 15 → 18 titles, 14.5 → 16 body), and Cormorant's small x-height can look lighter at small sizes.
VI: Một số màn có thể bị cắt chữ, chật hoặc quá cao ở nơi cỡ chữ tăng (vd. tiêu đề 15 → 18, thân bài 14.5 → 16); x-height nhỏ của Cormorant có thể trông nhẹ ở cỡ nhỏ.

## Proposed fix / Hướng xử lý
EN: Walk through every screen on a device, adjust line heights/constraints, then replace the stale "Lora" comments.
VI: Duyệt từng màn trên thiết bị, chỉnh line-height/constraint rồi thay các comment "Lora" cũ.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
