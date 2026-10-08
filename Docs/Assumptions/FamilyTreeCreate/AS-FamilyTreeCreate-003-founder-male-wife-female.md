---
id: AS-FamilyTreeCreate-003
title: The founder is always male and the optional spouse always female
title_vi: Thủy tổ luôn là nam và người phối ngẫu (nếu có) luôn là nữ
feature: FamilyTreeCreate
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTreeCreate/ILFamilyTreeCreateUseCase.swift:100
source: Docs/InnerLamp project/IL-GiaPha.dc.html (createClan — founder `s:'m'`, field "Vợ thủy tổ")
owner: Product / BA
---

## Assumption / Giả định
EN: The form has no gender field: the founder is stored as male and the optional "Vợ thủy tổ" as female, linked to the founder. The wife is stored without birth/death data and without being a clan head.
VI: Form không có ô giới tính: thủy tổ được lưu là nam và "Vợ thủy tổ" (không bắt buộc) là nữ, liên kết với thủy tổ. Người vợ được lưu không có năm sinh/mất và không phải tộc trưởng.

## Rationale / Cơ sở giả định
EN: Follows the prototype, which labels the field "Vợ thủy tổ" and stores `s:'m'` for the founder (clans are traced through the male line).
VI: Theo prototype: ô tên "Vợ thủy tổ" và thủy tổ lưu `s:'m'` (dòng họ tính theo họ cha).
 
## Implications if wrong / Hệ quả nếu sai
EN: A female founder or same-sex couple would need a gender choice on the form; the entity already supports it.
VI: Thủy tổ nữ hoặc cặp cùng giới cần thêm lựa chọn giới tính ở form; entity đã hỗ trợ sẵn.

## Validation / Cách xác nhận
EN: Confirm with Product that the founder is always male.
VI: Xác nhận với Product thủy tổ luôn là nam.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
