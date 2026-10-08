---
id: AS-FamilyTree-003
title: The tree is opened from a "Xem gia phả" button on the Sổ giỗ list
title_vi: Cây gia phả được mở từ nút "Xem gia phả" trên danh sách Sổ giỗ
feature: FamilyTree
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/Memorial/ILMemorialViewController.swift:86
  - InnerLamp/Presentation/Scenes/Memorial/ILMemorialCoordinator.swift:56
source: User decision during the il-screen-builder run (parent flow: Memorial); the prototype shows it as the bottom-nav tab "Cây"
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype shows the tree as the first of five bottom tabs; this build instead reaches it from a ghost button under the Sổ giỗ chạp list and hides the bottom nav like other child screens.
VI: Prototype hiển thị cây là tab đầu trong năm tab đáy; bản build này mở nó từ nút ghost dưới danh sách Sổ giỗ chạp và ẩn thanh điều hướng đáy như các màn con khác.

## Rationale / Cơ sở giả định
EN: The app's tab bar has no such tabs and the project owner chose Memorial as the parent flow.
VI: Tab bar của app chưa có các tab đó và chủ dự án đã chọn Memorial làm flow cha.

## Implications if wrong / Hệ quả nếu sai
EN: The entry point would move (Home link, Profile row, or a tab) — a coordinator/UI change only.
VI: Điểm vào sẽ đổi (link ở Home, dòng ở Profile hoặc tab) — chỉ là thay đổi coordinator/UI.

## Validation / Cách xác nhận
EN: Confirm the final entry point with Product/Design.
VI: Chốt điểm vào cuối cùng với Product/Design.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
