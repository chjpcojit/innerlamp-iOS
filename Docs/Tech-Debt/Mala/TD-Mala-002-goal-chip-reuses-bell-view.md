---
id: TD-Mala-002
title: Goal chips reuse Bell's feature-scoped ILBellChipView
title_vi: Chip mục tiêu dùng lại ILBellChipView của màn Bell (feature-scoped)
feature: Mala
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Mala/ILMalaViewController.swift
  - InnerLamp/Presentation/Scenes/Bell/Views/ILBellChipView.swift
---

## Description / Mô tả
EN: Mala imports `ILBellChipView` from the Bell scene (immersive `--il-med-*` pill) instead of a shared component.
VI: Mala dùng `ILBellChipView` của scene Bell (pill nền immersive `--il-med-*`) thay vì component dùng chung.

## Why it was taken on / Lý do chấp nhận nợ
EN: Moving it into `DesignSystem/Components` would touch Bell, which was out of scope for this redesign.
VI: Chuyển nó vào `DesignSystem/Components` sẽ phải sửa Bell, nằm ngoài phạm vi lần redesign này.

## Impact / Ảnh hưởng
EN: A cross-feature dependency; renaming or restyling the Bell chip silently changes Mala.
VI: Phụ thuộc chéo giữa các feature; đổi tên/kiểu chip của Bell sẽ vô tình đổi cả Mala.

## Proposed fix / Hướng xử lý
EN: Promote it to `DesignSystem/Components/ILImmersiveChipView` and update both screens.
VI: Nâng lên `DesignSystem/Components/ILImmersiveChipView` và cập nhật cả hai màn.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
