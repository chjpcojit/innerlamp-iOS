---
id: AS-FamilyTreeChronicle-003
title: Milestone years are 1–4 digits, not later than the current year, and optional
title_vi: Năm của mốc có 1–4 chữ số, không quá năm hiện tại và có thể để trống
feature: FamilyTreeChronicle
level: Low
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTreeChronicle/ILFamilyTreeChronicleUseCase.swift:101
source: Docs/InnerLamp project/IL-GiaPha.dc.html (milestone year input: digits only, 4 characters; no range check in the prototype)
owner: Product / BA
---

## Assumption / Giả định
EN: A milestone year, when filled, is a positive number of at most four digits and not after the current year; a milestone may have text without a year. Nothing is checked against the founder's birth year.
VI: Năm của mốc, nếu có, là số dương tối đa bốn chữ số và không sau năm hiện tại; mốc có thể chỉ có nội dung không có năm. Không đối chiếu với năm sinh của thủy tổ.

## Rationale / Cơ sở giả định
EN: The prototype only limits the input to four digits; a future year is clearly wrong for a history record, so the current year is the upper bound (as in the other FamilyTree forms).
VI: Prototype chỉ giới hạn bốn chữ số; năm tương lai rõ ràng sai với ghi chép lịch sử nên lấy năm hiện tại làm cận trên (giống các form FamilyTree khác).

## Implications if wrong / Hệ quả nếu sai
EN: Records of events before the founder, or approximate years, would be rejected or accepted incorrectly.
VI: Mốc trước thời thủy tổ hoặc năm ước lượng có thể bị từ chối hoặc chấp nhận sai.

## Validation / Cách xác nhận
EN: Confirm with Product; adjust `apply` in the UseCase.
VI: Xác nhận với Product; chỉnh `apply` trong UseCase.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
