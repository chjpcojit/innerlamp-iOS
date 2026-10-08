---
id: AS-Reader-001
title: Reader starts playing automatically for sutras with audio
title_vi: Reader tự phát khi mở kinh có audio
feature: Reader
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Reader/ILReaderUseCase.swift:57
source: Docs/InnerLamp project/InnerLamp Prototype.dc.html (isReader)
owner: Product / BA
---

## Assumption / Giả định
EN: Opening the Reader on a sutra with audio starts chanting at once; text-only sutras open paused.
VI: Mở Reader với kinh có audio sẽ tụng ngay; kinh chỉ có văn bản mở ở trạng thái tạm dừng.

## Rationale / Cơ sở giả định
EN: Prototype "Tụng theo" sets `rPlay: !!S.audio`.
VI: Prototype "Tụng theo" đặt `rPlay: !!S.audio`.

## Implications if wrong / Hệ quả nếu sai
EN: Unexpected autoplay (e.g. when entering from the library list).
VI: Tự phát ngoài ý muốn (vd. khi vào từ danh sách Thư viện).

## Validation / Cách xác nhận
EN: Confirm with design whether every entry point (chapter row, library) should autoplay.
VI: Hỏi design xem mọi lối vào (hàng phẩm, Thư viện) có tự phát không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
