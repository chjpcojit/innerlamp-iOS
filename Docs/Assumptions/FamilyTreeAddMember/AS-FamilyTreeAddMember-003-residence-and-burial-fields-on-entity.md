---
id: AS-FamilyTreeAddMember-003
title: residence and burialPlace added to the member entity without an API contract
title_vi: Thêm residence và burialPlace vào entity thành viên khi chưa có hợp đồng API
feature: FamilyTreeAddMember
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/Entities/ILFamilyTreeEntity.swift
source: Docs/InnerLamp project/IL-GiaPha.dc.html (prototype logic, not a confirmed business rule)
owner: Product / BA
---

## Assumption / Giả định
EN: `ILFamilyMemberEntity` gets optional `residence` (living) and `burialPlace` (deceased), shown in the detail sheet; `dharmaName` and `tabletTemple` stay unsourced.
VI: `ILFamilyMemberEntity` có thêm `residence` (còn sống) và `burialPlace` (đã mất) tùy chọn, hiện ở sheet chi tiết; `dharmaName` và `tabletTemple` vẫn chưa có nguồn.

## Rationale / Cơ sở giả định
EN: The form collects both values (per design); dropping them would lose user input. Defaults to nil so existing code is unaffected. Partially addresses TD-FamilyTree-009.
VI: Form thu thập cả hai giá trị (theo design); bỏ đi sẽ mất dữ liệu người nhập. Mặc định nil nên code cũ không ảnh hưởng. Giải quyết một phần TD-FamilyTree-009.

## Implications if wrong / Hệ quả nếu sai
EN: The real API may name or shape these fields differently; mapping would change.
VI: API thật có thể đặt tên/hình dạng khác; phần mapping sẽ phải đổi.

## Validation / Cách xác nhận
EN: Confirm the clan-book contract with Backend/Product.
VI: Xác nhận hợp đồng gia phả với Backend/Product.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
