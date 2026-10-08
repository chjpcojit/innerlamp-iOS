---
id: AS-FamilyTree-005
title: Lifespan and age are computed as in the prototype
title_vi: Tuổi thọ và tuổi được tính như trong prototype
feature: FamilyTree
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeFormatter.swift:74
source: Gia Pha Mobile.dc.html (`thọ ' + (d - b + 1) + ' tuổi'`, `2026 - b`)
owner: Product / BA
---

## Assumption / Giả định
EN: A deceased person's age at death is `deathYear - birthYear + 1` (Vietnamese counting); a living person's age is `currentYear - birthYear`; when only one of the two years is known the sheet shows just that year.
VI: Tuổi thọ của người đã mất là `deathYear - birthYear + 1` (tính tuổi mụ); tuổi người còn sống là `currentYear - birthYear`; khi chỉ biết một trong hai năm thì sheet chỉ hiện năm đó.

## Rationale / Cơ sở giả định
EN: It reproduces the prototype's formulas, with the current year taken from the clock instead of the constant 2026.
VI: Lặp lại công thức của prototype, lấy năm hiện tại từ đồng hồ thay vì hằng số 2026.

## Implications if wrong / Hệ quả nếu sai
EN: Ages shown could be off by one year.
VI: Tuổi hiển thị có thể lệch một năm.

## Validation / Cách xác nhận
EN: Confirm the counting convention with Product.
VI: Xác nhận quy ước tính tuổi với Product.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
