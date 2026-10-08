---
id: AS-Mala-001
title: Switching goal restarts the count; quarter haptic follows goal / 4
title_vi: Đổi mục tiêu thì đếm lại từ 0; rung mỗi phần tư theo goal / 4
feature: Mala
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Mala/ILMalaUseCase.swift
  - InnerLamp/Domain/Entities/ILMalaEntity.swift
source: Docs/InnerLamp icon consistency/InnerLamp Prototype.dc.html (screen mala — mlTargets)
owner: Product / Design
---

## Assumption / Giả định
EN: Picking a different goal chip resets the count to 0 and keeps the round number (as the prototype does). The light haptic fires every `goal / 4` beads (5, 10, 15 for 21; 13, 26, 39 for 54), not every 27 beads.
VI: Chọn chip mục tiêu khác sẽ đặt lại số đếm về 0 và giữ số vòng (giống prototype). Rung nhẹ mỗi `goal / 4` hạt (5, 10, 15 với 21; 13, 26, 39 với 54), không phải mỗi 27 hạt.

## Rationale / Cơ sở giả định
EN: The prototype resets `beads` on chip pick; it gives no haptic spec for 21/54, and the existing code already used a quarter of the goal.
VI: Prototype đặt lại `beads` khi chọn chip; không có đặc tả rung cho 21/54, và code hiện tại vốn đã dùng một phần tư của goal.

## Implications if wrong / Hệ quả nếu sai
EN: Minor — one use-case rule to change; the 27-bead "mother" bead markers are independent of the goal.
VI: Nhỏ — chỉ sửa một quy tắc ở use case; hạt mẹ mỗi 27 hạt không phụ thuộc goal.

## Validation / Cách xác nhận
EN: Ask Design whether haptics should follow the 27-bead mother beads regardless of goal.
VI: Hỏi Design xem rung có nên theo hạt mẹ mỗi 27 hạt bất kể goal hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
