---
id: AS-Reader-002
title: The −10s / +10s buttons move 2 lines
title_vi: Nút −10s / +10s nhảy 2 dòng
feature: Reader
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Reader/ILReaderViewModel.swift:30
source: Docs/InnerLamp project/InnerLamp Prototype.dc.html (isReader)
owner: Product / BA
---

## Assumption / Giả định
EN: Until real audio exists, −10s/+10s jump 2 lines back/forward.
VI: Khi chưa có audio thật, −10s/+10s nhảy lùi/tiến 2 dòng.

## Rationale / Cơ sở giả định
EN: Prototype `rdBack`/`rdFwd` use ±2 lines.
VI: Prototype `rdBack`/`rdFwd` dùng ±2 dòng.

## Implications if wrong / Hệ quả nếu sai
EN: Labels would mislead once audio seeks by real seconds.
VI: Nhãn sẽ gây hiểu nhầm khi audio tua theo giây thật.

## Validation / Cách xác nhận
EN: Revisit when real audio lands (see TD-Reader-001).
VI: Xem lại khi có audio thật (xem TD-Reader-001).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
