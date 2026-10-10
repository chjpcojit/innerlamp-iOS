---
id: AS-Main-001
title: Bottom nav dark fade uses ILSurface and lamp pressed state is a dimmed alpha
title_vi: Gradient tối của thanh đáy dùng ILSurface và trạng thái nhấn nút đèn là giảm alpha
feature: Main
level: Low
status: Unvalidated
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILBottomNavBar.swift
source: Docs/innerlamp-project/project/IL-BottomNav.dc.html (dark `fade` = #1C1814, no pressed state defined)
owner: Design
---

## Assumption / Giả định
EN: In dark mode the bottom nav fades to the shared `ILColors.surface` (#211D17) instead of the prototype's literal `#1C1814`. The lamp button has no pressed design, so it dims to alpha 0.8 while pressed (the previous outline-icon-on-press variant was dropped with the new solid icon set).
VI: Ở chế độ tối, thanh đáy fade về `ILColors.surface` (#211D17) dùng chung thay vì `#1C1814` của prototype. Nút đèn không có thiết kế trạng thái nhấn nên giảm alpha 0.8 khi nhấn (biến thể icon nét khi nhấn đã bỏ cùng bộ icon đặc mới).

## Rationale / Cơ sở giả định
EN: Avoids adding a one-off color token for a 3-level lightness difference; the prototype defines nothing for press.
VI: Tránh thêm token màu riêng cho chênh lệch rất nhỏ; prototype không định nghĩa trạng thái nhấn.

## Implications if wrong / Hệ quả nếu sai
EN: Slightly lighter dark bar than the design; pressed feedback differs from design intent. Fixable in one file.
VI: Thanh tối sáng hơn thiết kế một chút; phản hồi khi nhấn khác ý đồ thiết kế. Sửa trong một file.

## Validation / Cách xác nhận
EN: Designer compares the dark bar and pressed lamp on device.
VI: Designer so sánh thanh tối và nút đèn khi nhấn trên thiết bị.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
