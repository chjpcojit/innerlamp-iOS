---
id: TD-FamilyTree-007
title: "Hồ sơ đầy đủ" opens nothing yet
title_vi: "Hồ sơ đầy đủ" chưa mở màn nào
feature: FamilyTree
level: Medium
status: Resolved
created: 2026-10-03
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeCoordinator.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeDetailSheetView.swift
---

## Description / Mô tả
EN: The filled bottom pill sends `.openProfile(memberID:)`; the coordinator prints a TODO line because no member-profile screen exists.
VI: Nút đặc cuối sheet phát `.openProfile(memberID:)`; coordinator chỉ in dòng TODO vì chưa có màn hồ sơ thành viên.

## Why it was taken on / Lý do chấp nhận nợ
EN: The member-profile screen is not specified (⚠️ Not confirmed in requirements v2.0).
VI: Màn hồ sơ thành viên chưa có spec (⚠️ Not confirmed trong requirements v2.0).

## Impact / Ảnh hưởng
EN: Users cannot open a full profile.
VI: Người dùng chưa mở được hồ sơ đầy đủ.

## Proposed fix / Hướng xử lý
EN: Write the member-profile spec and screen; route `.openProfile` to its coordinator.
VI: Viết spec và màn hồ sơ thành viên; chuyển `.openProfile` sang coordinator của màn đó.

## Resolution / Kết quả xử lý
EN: 2026-10-04 — "Hồ sơ đầy đủ" now opens the member profile (view + edit), scene `FamilyTreeMember`; `ILFamilyTreeCoordinator.showProfile(memberID:)` routes `.openProfile`. Not committed yet.
VI: 2026-10-04 — "Hồ sơ đầy đủ" nay mở màn hồ sơ thành viên (xem + sửa), scene `FamilyTreeMember`; `ILFamilyTreeCoordinator.showProfile(memberID:)` điều hướng `.openProfile`. Chưa commit.
