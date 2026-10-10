---
id: TD-Profile-001
title: Default cover photo asset not added — cover shows a gradient
title_vi: Chưa có ảnh bìa mặc định — bìa đang hiển thị gradient
feature: Profile
level: Low
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Scenes/Profile/Views/ILProfileHeaderView.swift:229
---

## Description / Mô tả
EN: The agreed "bundled default cover image" has no photo in the repo and none could be authored, so the 250pt cover renders the `canvasWarmEnd1 → tint` gradient. Parallax, stretch and fade already work on top of it.
VI: "Ảnh bìa mặc định bundled" đã chọn nhưng repo chưa có ảnh nào, nên bìa 250pt đang là gradient `canvasWarmEnd1 → tint`. Parallax, giãn và fade đã hoạt động trên nền này.

## Why it was taken on / Lý do chấp nhận nợ
EN: The photo is a design/content asset, not code; blocking the whole screen on it was not worth it.
VI: Ảnh là tài nguyên thiết kế/nội dung, không phải code; không đáng chặn cả màn hình vì nó.

## Impact / Ảnh hưởng
EN: Visual only — header looks plainer than the prototype.
VI: Chỉ ảnh hưởng thị giác — header đơn giản hơn prototype.

## Proposed fix / Hướng xử lý
EN: Add `profile_cover_default.imageset` under `Assets.xcassets/Icons`, an `illustration("profile_cover_default")` constant in `ILIcons`, and call `headerView.setCoverImage(ILIcons.profileCoverDefault)` in `ILProfileViewController.setupViews()`.
VI: Thêm `profile_cover_default.imageset` vào `Assets.xcassets/Icons`, hằng `illustration("profile_cover_default")` trong `ILIcons`, và gọi `headerView.setCoverImage(ILIcons.profileCoverDefault)` trong `ILProfileViewController.setupViews()`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
