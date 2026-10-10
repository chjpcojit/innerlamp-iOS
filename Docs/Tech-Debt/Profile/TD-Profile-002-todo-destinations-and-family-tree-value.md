---
id: TD-Profile-002
title: Donate and merit-book destinations are TODO; family-tree row has no value
title_vi: Màn Ủng hộ và Sổ công đức chưa có; hàng Gia phả chưa có giá trị phụ
feature: Profile
level: Medium
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Scenes/Profile/ILProfileCoordinator.swift:42
  - InnerLamp/Presentation/Scenes/Profile/Views/ILProfileMenuCardView.swift:30
---

## Description / Mô tả
EN: `.openDonate` and `.openMeritBook` are emitted but the coordinator ignores them (no target screens). The "Gia phả dòng họ" row shows no trailing family-tree name ("Họ Nguyễn Hữu" in the prototype) because Profile has no source for it.
VI: `.openDonate` và `.openMeritBook` được phát nhưng coordinator bỏ qua (chưa có màn đích). Hàng "Gia phả dòng họ" chưa hiện tên gia phả ("Họ Nguyễn Hữu" trong prototype) vì Profile chưa có nguồn dữ liệu.

## Why it was taken on / Lý do chấp nhận nợ
EN: Target screens are separate features (Docs/Specs/Profile tasks.md Phase 4); the user asked for TODO events.
VI: Màn đích là feature riêng (Docs/Specs/Profile tasks.md Phase 4); người dùng yêu cầu để event TODO.

## Impact / Ảnh hưởng
EN: Two taps do nothing; one row lacks its value.
VI: Hai thao tác chạm chưa có phản hồi; một hàng thiếu giá trị phụ.

## Proposed fix / Hướng xử lý
EN: Build the donate and merit-book screens and wire them; expose the active family-tree name to Profile (UseCase field) once its source is confirmed.
VI: Dựng màn Ủng hộ và Sổ công đức rồi nối; đưa tên gia phả đang chọn vào Profile (field UseCase) khi nguồn được xác nhận.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
