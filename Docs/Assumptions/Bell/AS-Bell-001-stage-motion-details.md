---
id: AS-Bell-001
title: Stage animation details approximated from the HTML prototype
title_vi: Chi tiết hoạt ảnh sân khấu được xấp xỉ từ prototype HTML
feature: Bell
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Bell/Views/ILBellPadView.swift
source: Docs/InnerLamp icon consistency/InnerLamp Prototype.dc.html (_bAnim, _bStageEl)
owner: Design
---

## Assumption / Giả định
EN: Mallet swing, fish dip, bowl sway and ripples copy the prototype's keyframes. The roll's per-strike swing length (the prototype's `_moDur`) is derived from the time since the previous strike (0.85x, 60–260 ms) because the ViewModel does not expose the roll gaps. The strike sound is not delayed by 70 ms to sync with the swing. Strikes keep firing on touch-up, as before.
VI: Hoạt ảnh dùi, mõ, chuông và sóng lấy theo keyframe của prototype. Độ dài mỗi nhịp khi dồn mõ suy ra từ khoảng cách giữa hai tiếng (0.85x, 60–260 ms) vì ViewModel không lộ khoảng cách này. Âm thanh không trễ 70 ms để khớp với dùi. Gõ vẫn tính khi nhả tay như trước.

## Rationale / Cơ sở giả định
EN: Avoids changing the ViewModel/audio path for a visual-only request.
VI: Tránh đổi ViewModel/audio cho yêu cầu chỉ về giao diện.

## Implications if wrong / Hệ quả nếu sai
EN: Slight timing mismatch between sound and swing; fixable inside the pad view.
VI: Lệch nhẹ giữa âm thanh và dùi; sửa được trong pad view.

## Validation / Cách xác nhận
EN: Check on device against the prototype.
VI: Kiểm tra trên thiết bị so với prototype.

## Outcome / Kết luận
EN: _(pending)_
VI: _(chờ xác nhận)_
