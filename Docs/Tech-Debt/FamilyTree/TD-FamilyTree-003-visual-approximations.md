---
id: TD-FamilyTree-003
title: Fonts and medallion details approximate the prototype
title_vi: Font và chi tiết huy hiệu chỉ xấp xỉ prototype
feature: FamilyTree
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Common/DesignSystem/Tokens/ILTypography.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeMedallionView.swift
---

## Description / Mô tả
EN: The prototype uses Cormorant Garamond, which is not bundled — the `tree*` presets use Lora. Medallion plates are flat colors (the prototype uses small gradients) and the 5°/5° conic tick ring is a dashed hex stroke. The tree palette is fixed and does not follow dark mode. The seal 長 is plain text in Lora.
VI: Prototype dùng Cormorant Garamond nhưng app chưa bundle — các preset `tree*` dùng Lora. Nền huy hiệu là màu phẳng (prototype dùng gradient nhẹ) và vòng vạch conic 5°/5° được thay bằng nét đứt hình lục giác. Bảng màu cây cố định, không theo dark mode. Con dấu 長 là chữ Lora thường.

EN: Update (v2.0, 2026-10-03): medallion gradients, the 72-tick conic ring, collar notch, hair stripes and the double-ring seal are now implemented; only the Cormorant Garamond substitution (Lora) and the fixed (non-dark-mode) palette remain.
VI: Cập nhật (v2.0, 2026-10-03): gradient huy hiệu, vòng 72 vạch conic, khuyết cổ áo, sọc tóc và con dấu hai viền đã được làm; chỉ còn việc thay Cormorant Garamond bằng Lora và bảng màu cố định (không theo dark mode).

## Why it was taken on / Lý do chấp nhận nợ
EN: No font asset to bundle without a licence/asset decision; the differences are cosmetic.
VI: Chưa có font để bundle khi chưa chốt license/asset; khác biệt chỉ về thẩm mỹ.

## Impact / Ảnh hưởng
EN: Slightly different look from the prototype.
VI: Giao diện hơi khác prototype.

## Proposed fix / Hướng xử lý
EN: Bundle Cormorant Garamond and point the `tree*` presets at it; add gradient plates and a conic tick ring to the medallion if the design review asks.
VI: Bundle Cormorant Garamond và đổi các preset `tree*` sang font đó; thêm nền gradient và vòng vạch conic cho huy hiệu nếu design review yêu cầu.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
