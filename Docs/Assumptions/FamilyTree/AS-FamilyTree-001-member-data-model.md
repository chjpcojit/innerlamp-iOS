---
id: AS-FamilyTree-001
title: Clan data is a flat member list with parent and spouse ids
title_vi: Dữ liệu dòng họ là danh sách phẳng với id cha/mẹ và vợ/chồng
feature: FamilyTree
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/Entities/ILFamilyTreeEntity.swift:33
source: Docs/InnerLamp icon consistency/Gia Pha Mobile.dc.html (member list in the prototype script)
owner: Product / BA
---

## Assumption / Giả định
EN: A member has at most one blood parent (`parentID`) and at most one spouse; a spouse who married in carries `spouseID` and no `parentID`; the order of children in the list is their birth order, so the first child of the founder is the "chi trưởng". The founder is the first member with no parent who is not married in.
VI: Một thành viên có tối đa một cha/mẹ ruột (`parentID`) và một vợ/chồng; người kết hôn vào có `spouseID` và không có `parentID`; thứ tự con trong danh sách là thứ tự sinh, nên con đầu của thủy tổ là "chi trưởng". Thủy tổ là thành viên đầu tiên không có cha/mẹ và không phải người kết hôn vào.

## Rationale / Cơ sở giả định
EN: It is exactly how the prototype's sample data is shaped and what its relation/lineage logic reads.
VI: Đúng với cấu trúc dữ liệu mẫu trong prototype và logic quan hệ/huyết thống của nó.

## Implications if wrong / Hệ quả nếu sai
EN: Remarriage, adoption, or two parents on record need a different model; the Entity, Graph and Layout would be reworked.
VI: Tái hôn, con nuôi hoặc ghi cả hai cha mẹ cần mô hình khác; Entity, Graph và Layout phải làm lại.

## Validation / Cách xác nhận
EN: Confirm the real data model with Product/BA before building the Repository (TD-FamilyTree-001).
VI: Chốt mô hình dữ liệu thật với Product/BA trước khi làm Repository (TD-FamilyTree-001).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
