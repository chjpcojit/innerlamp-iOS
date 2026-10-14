---
id: AS-LightLamp-003
title: A lamp goes out after its chosen number of days
title_vi: Đèn tắt sau số ngày đã chọn
feature: LightLamp
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/Entities/ILLampEntity.swift:41
  - InnerLamp/Domain/UseCases/LightLamp/ILLightLampUseCase.swift:50
source: Docs/Specs/LightLamp/requirements.md (Pending — real-time expiry vs static duration, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: A lamp lit on day D for N days shines through day D+N-1 (counting calendar days in the device time zone) and disappears from the garden afterwards. The lit day counts as day 1; a 1-day lamp shows "Sáng đến hết hôm nay".
VI: Đèn thắp ngày D trong N ngày sáng đến hết ngày D+N-1 (tính theo ngày lịch ở múi giờ thiết bị) rồi biến khỏi vườn đèn. Ngày thắp là ngày 1; đèn 1 ngày hiển thị "Sáng đến hết hôm nay".

## Rationale / Cơ sở giả định
EN: The prototype shows "Còn N ngày" and lamp durations of 1/7/21/49 days, which only make sense if lamps expire.
VI: Prototype hiển thị "Còn N ngày" và thời gian sáng 1/7/21/49 ngày, chỉ hợp lý nếu đèn hết hạn.

## Implications if wrong / Hệ quả nếu sai
EN: If the duration is only a label, users lose lamps they expected to keep; the counting convention (inclusive of the lit day) may differ from Product's.
VI: Nếu thời gian chỉ là nhãn, người dùng mất đèn mà họ mong giữ; cách đếm (tính cả ngày thắp) có thể khác ý Product.

## Validation / Cách xác nhận
EN: Confirm the expiry rule and the day-counting convention with Product.
VI: Xác nhận quy tắc hết hạn và cách đếm ngày với Product.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
