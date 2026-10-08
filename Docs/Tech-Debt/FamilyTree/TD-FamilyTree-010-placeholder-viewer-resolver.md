---
id: TD-FamilyTree-010
title: Viewer ("BẠN") is picked by a placeholder resolver, not the signed-in account
title_vi: Người xem ("BẠN") đang lấy từ resolver tạm, chưa theo tài khoản đăng nhập
feature: FamilyTree
level: Medium
status: Open
created: 2026-10-03
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTree/ILFamilyTreeViewerResolver.swift:19
  - InnerLamp/App/DIContainer.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
---

## Description / Mô tả
EN: `ILPlaceholderFamilyTreeViewerResolver` marks the clan head as "BẠN" so the pill, gold zoom button, legend item and "Với bạn" row can be built and tested. It does not look at the signed-in account. Since 2026-10-04 a book without a clan head (a freshly created one) falls back to the living blood-line member of the newest generation, so the merged "Nội – ngoại" view has a viewer to start from; only the paternal book (and the merged view) shows "BẠN".
VI: `ILPlaceholderFamilyTreeViewerResolver` coi tộc trưởng là "BẠN" để dựng và kiểm thử huy hiệu, nút zoom vàng, mục chú giải và dòng "Với bạn". Resolver này không xét tài khoản đăng nhập. Từ 2026-10-04, gia phả không có tộc trưởng (vừa tạo) lấy người ruột thịt còn sống thuộc đời mới nhất, để view gộp "Nội – ngoại" có người xuất phát; chỉ gia phả bên nội (và view gộp) hiện "BẠN".

## Why it was taken on / Lý do chấp nhận nợ
EN: Product confirmed the UI first; the account-to-member link (by name or phone) is a later step and needs the real tree data source (TD-FamilyTree-001).
VI: Product xác nhận làm UI trước; việc liên kết tài khoản với thành viên (theo tên hoặc số điện thoại) làm sau và cần nguồn dữ liệu gia phả thật (TD-FamilyTree-001).

## Impact / Ảnh hưởng
EN: Once a real tree loads, the wrong person (the clan head) would show "BẠN" and "Với bạn" would be relative to them.
VI: Khi có cây gia phả thật, sai người (tộc trưởng) sẽ hiện "BẠN" và "Với bạn" sẽ tính theo người đó.

## Proposed fix / Hướng xử lý
EN: Add an `ILFamilyTreeViewerResolving` implementation that matches the signed-in user's name or phone number against the tree's members (return `nil` when there is no match), and swap it in `DIContainer.makeFamilyTreeViewModel()`. Nothing else changes. Add resolver tests.
VI: Thêm bản triển khai `ILFamilyTreeViewerResolving` khớp tên hoặc số điện thoại của người dùng đăng nhập với các thành viên trong cây (trả `nil` nếu không khớp), rồi thay trong `DIContainer.makeFamilyTreeViewModel()`. Không phải sửa gì khác. Bổ sung test cho resolver.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
