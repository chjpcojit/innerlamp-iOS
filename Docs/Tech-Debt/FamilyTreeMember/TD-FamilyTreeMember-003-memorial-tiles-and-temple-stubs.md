---
id: TD-FamilyTreeMember-003
title: Memorial tiles and the tablet-temple link are TODO stubs
title_vi: Các ô tưởng niệm và liên kết nơi thờ bài vị là stub TODO
feature: FamilyTreeMember
level: Medium
status: Open
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Presentation/Scenes/FamilyTreeMember/ILFamilyTreeMemberCoordinator.swift
---

## Description / Mô tả
EN: "Nhắc giỗ", "Thắp đèn", "Tụng kinh" and the "Bài vị thờ tại" link emit nav events whose coordinator branch is a one-line `print("TODO: ...")`.
VI: "Nhắc giỗ", "Thắp đèn", "Tụng kinh" và liên kết "Bài vị thờ tại" phát sự kiện điều hướng nhưng coordinator chỉ có `print("TODO: ...")` một dòng.

## Why it was taken on / Lý do chấp nhận nợ
EN: Destinations (Sổ giỗ, Bell/Reader, temple page) are unconfirmed — same open question as TD-FamilyTree-005, -006, -008.
VI: Chưa xác nhận đích đến (Sổ giỗ, Chuông mõ/Đọc kinh, trang chùa) — cùng câu hỏi mở với TD-FamilyTree-005, -006, -008.

## Impact / Ảnh hưởng
EN: The four controls do nothing visible.
VI: Bốn nút này chưa có tác dụng nhìn thấy được.

## Proposed fix / Hướng xử lý
EN: Wire each event to its destination once the hand-off flows are confirmed; share the destinations with the tree detail sheet.
VI: Nối từng sự kiện tới đích khi các luồng chuyển tiếp được xác nhận; dùng chung đích với detail sheet của cây.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
