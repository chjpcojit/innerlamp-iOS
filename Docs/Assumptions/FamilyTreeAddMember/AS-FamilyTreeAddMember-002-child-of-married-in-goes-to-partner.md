---
id: AS-FamilyTreeAddMember-002
title: A child of a married-in person is attached to that person's partner
title_vi: Con của người đi lấy chồng/vợ được gắn vào người phối ngẫu mang huyết thống
feature: FamilyTreeAddMember
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTreeAddMember/ILFamilyTreeAddMemberUseCase.swift
source: Docs/InnerLamp project/IL-GiaPha.dc.html (prototype logic, not a confirmed business rule)
owner: Product / BA
---

## Assumption / Giả định
EN: When the chosen relative married into the clan, "Con của" attaches the child to the relative's blood-line partner (so the child hangs under the couple).
VI: Khi người được chọn là dâu/rể, "Con của" gắn con vào người phối ngẫu mang huyết thống (con nằm dưới cặp vợ chồng).

## Rationale / Cơ sở giả định
EN: The entity model stores `parentID` only for blood descendants (AS-FamilyTree-001) and the prototype does the same.
VI: Mô hình entity chỉ lưu `parentID` cho con cháu huyết thống (AS-FamilyTree-001) và prototype cũng làm vậy.

## Implications if wrong / Hệ quả nếu sai
EN: The tree could not tell which parent a child was entered under.
VI: Cây không phân biệt được con được nhập dưới cha hay mẹ.

## Validation / Cách xác nhận
EN: Confirm with Product whether the mother's/father's identity must be kept separately.
VI: Xác nhận với Product xem có cần lưu riêng danh tính cha/mẹ hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
