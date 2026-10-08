---
id: AS-Reader-003
title: Auto-scroll anchors at 38% height; 2.6 s per line at 1.0×
title_vi: Tự cuộn neo ở 38% chiều cao; 2,6 giây/dòng ở 1.0×
feature: Reader
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Reader/ILReaderViewController.swift:11
  - InnerLamp/Domain/UseCases/Reader/ILReaderUseCase.swift:44
source: Docs/InnerLamp project/InnerLamp Prototype.dc.html (isReader)
owner: Product / BA
---

## Assumption / Giả định
EN: The current line is scrolled to 38% of the visible list height and advances every 2.6 s at 1.0×.
VI: Dòng hiện tại được cuộn tới 38% chiều cao vùng nhìn và chuyển mỗi 2,6 giây ở 1.0×.

## Rationale / Cơ sở giả định
EN: Constants taken from the prototype script (`clientHeight * 0.38`, `2600`).
VI: Hằng số lấy từ script prototype (`clientHeight * 0.38`, `2600`).

## Implications if wrong / Hệ quả nếu sai
EN: Pace may feel wrong for long lines or other sutras.
VI: Nhịp có thể không hợp với dòng dài hoặc kinh khác.

## Validation / Cách xác nhận
EN: Validate on device with real chanting speed.
VI: Kiểm tra trên thiết bị với tốc độ tụng thực tế.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
