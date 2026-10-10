---
id: AS-Profile-001
title: Profile cover image is a static default, not per-user
title_vi: Ảnh bìa hồ sơ là ảnh mặc định cố định, không theo người dùng
feature: Profile
level: Medium
status: Unvalidated
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Scenes/Profile/Views/ILProfileHeaderView.swift:229
source: Docs/Specs/Profile/requirements.md (cover image source, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Every user sees the same default cover (a warm gradient today). The prototype's `image-slot` ("Ảnh Phật pháp · ảnh bìa hồ sơ") may mean the user picks their own cover, or the backend supplies one — not confirmed.
VI: Mọi người dùng thấy cùng 1 ảnh bìa mặc định (hiện là gradient ấm). `image-slot` trong prototype ("Ảnh Phật pháp · ảnh bìa hồ sơ") có thể nghĩa là người dùng tự chọn ảnh, hoặc backend trả về — chưa xác nhận.

## Rationale / Cơ sở giả định
EN: No profile API or photo-picker flow exists; the user chose "bundled default image" on 2026-10-10. `ILProfileHeaderView.setCoverImage(_:)` is the single hook to feed a real image later.
VI: Chưa có API hồ sơ hay luồng chọn ảnh; người dùng chọn "ảnh mặc định bundled" ngày 2026-10-10. `ILProfileHeaderView.setCoverImage(_:)` là điểm duy nhất để nạp ảnh thật sau này.

## Implications if wrong / Hệ quả nếu sai
EN: If covers are per-user, the header needs an image source (picker + storage, or a DTO field), a loading state and a failure fallback; the stat/offset maths stays the same.
VI: Nếu bìa theo từng người dùng, header cần nguồn ảnh (chọn ảnh + lưu, hoặc trường DTO), trạng thái tải và fallback lỗi; phần tính offset giữ nguyên.

## Validation / Cách xác nhận
EN: Ask Product/BA whether the cover is user-chosen or server-provided, and its aspect ratio.
VI: Hỏi Product/BA bìa do người dùng chọn hay server cấp, và tỷ lệ khung ảnh.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
