---
id: TD-FamilyTree-008
title: "Bài vị thờ tại" temple link is a TODO stub
title_vi: Liên kết chùa "Bài vị thờ tại" là stub TODO
feature: FamilyTree
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeCoordinator.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeDetailSheetView.swift
---

## Description / Mô tả
EN: When a deceased member has an ancestral-tablet temple, the sheet shows it as an underlined link that sends `.openTemple(memberID:)`; the coordinator prints a TODO line. Today no member carries a temple (see TD-FamilyTree-009), so the link row is never visible with real data.
VI: Khi người đã mất có chùa thờ bài vị, sheet hiện thành liên kết gạch chân phát `.openTemple(memberID:)`; coordinator in dòng TODO. Hiện chưa thành viên nào có chùa (xem TD-FamilyTree-009) nên với dữ liệu thật dòng liên kết chưa bao giờ hiện.

## Why it was taken on / Lý do chấp nhận nợ
EN: No temple page/link target and no temple field on the member exist.
VI: Chưa có trang chùa/đích liên kết và chưa có trường chùa trên thành viên.

## Impact / Ảnh hưởng
EN: Link is inert once data exists.
VI: Khi có dữ liệu, liên kết vẫn chưa có tác dụng.

## Proposed fix / Hướng xử lý
EN: Add the temple reference to the member data, then route `.openTemple` to the temple detail screen.
VI: Thêm tham chiếu chùa vào dữ liệu thành viên, rồi chuyển `.openTemple` sang màn chi tiết chùa.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
