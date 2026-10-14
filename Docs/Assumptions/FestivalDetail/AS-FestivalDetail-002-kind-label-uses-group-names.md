---
id: AS-FestivalDetail-002
title: The kind eyebrow shows the event's group names
title_vi: Nhãn loại hiển thị tên các nhóm của sự kiện
feature: FestivalDetail
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/FestivalDetail/ILFestivalDetailViewModel.swift
source: Docs/Specs/FestivalDetail/requirements.md (⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype's kind label ("Lễ lớn", "Vía Bồ Tát", "Kỷ niệm"…) has no server field; the group names of the event ("Phật giáo", "Dân gian"…) joined by " · " are shown instead, or "Chưa có phân loại" when there are none.
VI: Nhãn loại của prototype ("Lễ lớn", "Vía Bồ Tát", "Kỷ niệm"…) không có field trên server; hiển thị tên các nhóm của sự kiện ("Phật giáo", "Dân gian"…) nối bằng " · ", hoặc "Chưa có phân loại" khi không có.

## Rationale / Cơ sở giả định
EN: Group names are the only classification the contract provides.
VI: Tên nhóm là phân loại duy nhất hợp đồng cung cấp.

## Implications if wrong / Hệ quả nếu sai
EN: The label reads differently from the prototype; cosmetic.
VI: Nhãn khác prototype; chỉ là thẩm mỹ.

## Validation / Cách xác nhận
EN: Ask design whether group names are acceptable or a "kind" field should be added to the API.
VI: Hỏi design xem tên nhóm có chấp nhận được không hay cần thêm field "kind" vào API.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
