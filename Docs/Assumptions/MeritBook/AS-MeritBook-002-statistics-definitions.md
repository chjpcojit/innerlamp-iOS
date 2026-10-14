---
id: AS-MeritBook-002
title: Statistics count every offering regardless of confirmation
title_vi: Thống kê tính mọi lần cúng dường, bất kể chùa đã xác nhận hay chưa
feature: MeritBook
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/MeritBook/ILMeritBookViewModel.swift:150
source: Docs/Specs/MeritBook/SRS.md (FR-002, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Year total sums all offerings dated in the current calendar year; lamp count is offerings with purpose "Thỉnh đèn tại chùa"; temple count is distinct temple names. Pending offerings are included.
VI: Tổng năm cộng mọi lần cúng dường trong năm dương lịch hiện tại; số đèn là các lần có mục đích "Thỉnh đèn tại chùa"; số chùa là số tên chùa khác nhau. Các lần đang chờ xác nhận vẫn được tính.

## Rationale / Cơ sở giả định
EN: Mirrors the prototype's `mr.stats` computation, which does not filter on status.
VI: Khớp cách tính `mr.stats` của prototype, không lọc theo trạng thái.

## Implications if wrong / Hệ quả nếu sai
EN: Figures could overstate what temples have actually received; small fix in one function.
VI: Số liệu có thể cao hơn thực tế chùa đã nhận; chỉ cần sửa một hàm.

## Validation / Cách xác nhận
EN: Ask product whether unconfirmed offerings should count; also whether temples are identified by id rather than name.
VI: Hỏi product có tính lần chưa xác nhận hay không; và có nên định danh chùa bằng id thay vì tên.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
