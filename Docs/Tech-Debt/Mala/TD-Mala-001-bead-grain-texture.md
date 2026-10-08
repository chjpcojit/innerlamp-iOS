---
id: TD-Mala-001
title: Wood-grain stripes on ordinary beads are not drawn
title_vi: Chưa vẽ vân gỗ trên các hạt thường
feature: Mala
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILMalaStrandView.swift
---

## Description / Mô tả
EN: The design draws a `repeating-linear-gradient` grain (random angle per bead) over each ordinary bead. `BeadLayer` reproduces the radial body, specular highlight, rim light, per-bead brightness and rotation, but not the stripes.
VI: Thiết kế vẽ vân `repeating-linear-gradient` (góc ngẫu nhiên theo từng hạt) lên mỗi hạt thường. `BeadLayer` đã có thân radial, điểm sáng, ánh rìa, độ đậm nhạt và góc xoay theo từng hạt, nhưng chưa có vân.

## Why it was taken on / Lý do chấp nhận nợ
EN: Core Animation has no repeating-gradient layer; faking it needs a pattern image or replicator per bead, and the effect is subtle at 27–40pt.
VI: Core Animation không có layer gradient lặp; muốn giả lập phải dùng ảnh pattern hoặc replicator cho từng hạt, trong khi hiệu ứng khá mờ ở kích thước 27–40pt.

## Impact / Ảnh hưởng
EN: Cosmetic — beads look slightly smoother than the prototype.
VI: Thẩm mỹ — hạt nhìn mượt hơn bản prototype một chút.

## Proposed fix / Hướng xử lý
EN: Render one grain tile as a `UIImage` (like the cord pattern) and add it as a masked sublayer, rotated with the bead.
VI: Vẽ một ô vân thành `UIImage` (như họa tiết dây) rồi thêm làm sublayer có mask, xoay cùng hạt.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
