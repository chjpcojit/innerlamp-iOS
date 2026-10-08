---
id: AS-FamilyTreeCreate-001
title: Year limits are 1300 up to the current year
title_vi: Giới hạn năm là từ 1300 đến năm hiện tại
feature: FamilyTreeCreate
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTreeCreate/ILFamilyTreeCreateUseCase.swift:70
source: Docs/InnerLamp project/IL-GiaPha.dc.html (createClan — 1300 and 2026 are hard-coded)
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype hard-codes the range 1300–2026. 2026 was the prototype's "today", so the build uses the current year instead; 1300 stays the lower bound. "Năm mất" must be ≥ "Năm sinh" and ≤ the current year.
VI: Prototype gán cứng khoảng 1300–2026. 2026 là "hôm nay" của prototype nên bản build dùng năm hiện tại; 1300 giữ làm cận dưới. "Năm mất" phải ≥ "Năm sinh" và ≤ năm hiện tại.

## Rationale / Cơ sở giả định
EN: A fixed 2026 would reject valid years from 2027 on.
VI: Gán cứng 2026 sẽ từ chối năm hợp lệ từ 2027 trở đi.

## Implications if wrong / Hệ quả nếu sai
EN: A different limit is a one-constant change in the UseCase.
VI: Đổi giới hạn chỉ là sửa một hằng số trong UseCase.

## Validation / Cách xác nhận
EN: Confirm the lower bound (1300) and the upper bound with Product.
VI: Xác nhận cận dưới (1300) và cận trên với Product.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
