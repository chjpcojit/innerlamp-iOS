---
id: AS-Home-001
title: Whole bead card opens Mala; Home no longer counts beads
title_vi: Cả thẻ tràng hạt mở màn Niệm Phật; Trang chủ không còn đếm hạt
feature: Home
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILMalaCounterView.swift
  - InnerLamp/Presentation/Scenes/Home/ILHomeViewController.swift
source: Docs/InnerLamp icon consistency/InnerLamp Prototype.dc.html (goMalaKeep)
owner: Product / Design
---

## Assumption / Giả định
EN: The new design replaces "tap bead = +1" and the "Bắt đầu lại" button with a card that opens Mala. The helper copy "Chạm để vào chuỗi niệm Phật." is my cleaned-up reading of the design's garbled "Chạm để vào lần chuỗi niệm Phật."
VI: Thiết kế mới thay "chạm hạt = +1" và nút "Bắt đầu lại" bằng thẻ mở màn Niệm Phật. Câu mô tả "Chạm để vào chuỗi niệm Phật." là bản chỉnh lại từ câu bị lỗi trong thiết kế.

## Rationale / Cơ sở giả định
EN: The prototype has no handler on the bead ring or a reset button; the card carries `goMalaKeep` and a "›".
VI: Prototype không còn handler ở vòng hạt hay nút reset; cả thẻ gắn `goMalaKeep` và dấu "›".

## Implications if wrong / Hệ quả nếu sai
EN: Users lose in-place counting on Home; restoring it means re-adding the two Inputs.
VI: Người dùng mất việc đếm ngay trên Trang chủ; khôi phục cần thêm lại hai Input.

## Validation / Cách xác nhận
EN: Confirm with design/product; confirm the helper wording.
VI: Xác nhận với design/product; xác nhận câu chữ mô tả.

## Outcome / Kết luận
EN: _(pending)_
VI: _(chờ xác nhận)_
