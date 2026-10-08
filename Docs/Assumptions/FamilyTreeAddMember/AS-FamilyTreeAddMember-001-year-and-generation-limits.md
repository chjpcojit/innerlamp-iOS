---
id: AS-FamilyTreeAddMember-001
title: Birth year ≥ 1700, death year ≤ current year, at most 7 generations
title_vi: Năm sinh ≥ 1700, năm mất ≤ năm hiện tại, tối đa 7 đời
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
EN: A new member must be born between 1700 and the current year, die between birth and the current year, and sit in generation 7 or earlier.
VI: Thành viên mới phải sinh từ 1700 đến năm hiện tại, mất từ năm sinh đến năm hiện tại, và thuộc đời 7 trở về trước.

## Rationale / Cơ sở giả định
EN: Taken from the prototype (`save()`); 7 is the number of generations the tree canvas currently lays out. The prototype used a fixed 2026 as the upper bound; the current year is used here, as in FamilyTreeCreate.
VI: Lấy từ prototype (`save()`); 7 là số đời mà canvas cây hiện bố trí. Prototype dùng cố định 2026 làm cận trên; ở đây dùng năm hiện tại, giống FamilyTreeCreate.

## Implications if wrong / Hệ quả nếu sai
EN: Real clans can be older or deeper; people would be unable to record them.
VI: Dòng họ thật có thể lâu đời hoặc nhiều đời hơn; người dùng sẽ không ghi được.

## Validation / Cách xác nhận
EN: Confirm the limits with Product; change `minimumYear` / `maximumGeneration` in the UseCase.
VI: Xác nhận giới hạn với Product; đổi `minimumYear` / `maximumGeneration` trong UseCase.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
