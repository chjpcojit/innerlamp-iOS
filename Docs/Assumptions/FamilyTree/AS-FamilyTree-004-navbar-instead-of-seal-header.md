---
id: AS-FamilyTree-004
title: A standard nav bar (back + search) replaces the seal header
title_vi: Thanh điều hướng chuẩn (quay lại + tìm) thay cho header có con dấu
feature: FamilyTree
level: Low
status: Invalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewController.swift
source: Gia Pha Mobile.dc.html (header with 譜 seal, search and "+" buttons)
owner: Product / BA
---

## Assumption / Giả định
EN: Because the screen is pushed, it uses `ILNavBar` (back, clan name as title, "Tìm" action, subtitle "quê · N đời · N người") instead of the prototype's seal header with a search icon and a "+" button.
VI: Vì màn được push nên dùng `ILNavBar` (quay lại, tên dòng họ làm tiêu đề, nút "Tìm", phụ đề "quê · N đời · N người") thay cho header có con dấu, icon tìm và nút "+" của prototype.

## Rationale / Cơ sở giả định
EN: A pushed screen needs a way back and the design system already has `ILNavBar`; the "+" is out of scope (TD-FamilyTree-002).
VI: Màn được push cần có lối quay lại và design system đã có `ILNavBar`; nút "+" ngoài phạm vi (TD-FamilyTree-002).

## Implications if wrong / Hệ quả nếu sai
EN: The header would be restyled to match the prototype.
VI: Header sẽ được làm lại cho giống prototype.

## Validation / Cách xác nhận
EN: Design review of the built screen on a device.
VI: Design review màn đã build trên thiết bị.

## Outcome / Kết luận
EN: Invalidated 2026-10-03 — requirements v2.0 adopt the prototype's seal header; `ILFamilyTreeHeaderView` replaces `ILNavBar` (back chevron kept, see AS-FamilyTree-008).
VI: Không còn đúng 2026-10-03 — requirements v2.0 dùng header có con dấu theo prototype; `ILFamilyTreeHeaderView` thay `ILNavBar` (giữ nút quay lại, xem AS-FamilyTree-008).
