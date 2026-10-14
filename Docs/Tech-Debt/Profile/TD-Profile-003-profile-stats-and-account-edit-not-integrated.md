---
id: TD-Profile-003
title: Profile stats still mock; avatar, email verification and PATCH not integrated
title_vi: Thống kê Hồ sơ vẫn là dữ liệu mẫu; avatar, xác thực email và PATCH chưa tích hợp
feature: Profile
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Profile/ILProfileUseCase.swift
  - InnerLamp/Presentation/Scenes/Profile/ILProfileViewModel.swift
---

## Description / Mô tả
EN: Only the account fields of `GET /v1/users/me` (email, dharma name) are integrated. Practice stats, heatmap, badges, merit counts, plan, reminder and community stay mock (backend has no such API). The avatar URL, ordination temple name, `email_verified`, and `PATCH /v1/users/me` + avatar upload endpoints are decoded or documented but not shown/used. The screen has no loading or error state: a failed load silently keeps the placeholder.
VI: Mới tích hợp phần tài khoản của `GET /v1/users/me` (email, pháp danh). Thống kê tu tập, heatmap, huy hiệu, công đức, gói, chuông, đạo tràng vẫn là dữ liệu mẫu (backend chưa có API). URL avatar, tên chùa xuất gia, `email_verified`, `PATCH /v1/users/me` và upload avatar đã được decode/ghi nhận nhưng chưa dùng. Màn hình chưa có trạng thái loading/lỗi: tải lỗi thì giữ dữ liệu tạm một cách im lặng.

## Why it was taken on / Lý do chấp nhận nợ
EN: Scope was "fetch my profile"; no stats API exists and there is no designed loading/error UI.
VI: Phạm vi là "lấy profile"; chưa có API thống kê và chưa có thiết kế UI loading/lỗi.

## Impact / Ảnh hưởng
EN: Mock name "Nguyễn Bình An" shows if the first load fails or while it is in flight; mock stats are shown as if real.
VI: Tên mẫu "Nguyễn Bình An" hiện khi tải lỗi hoặc đang tải; số liệu mẫu hiện như thật.

## Proposed fix / Hướng xử lý
EN: Add loading/error states and an empty-name placeholder; render avatar with `ILRemoteImageView` and refetch after `avatar_url_expires_at`; wire EditProfile to `PATCH /v1/users/me`; replace mock stats when a stats API exists.
VI: Thêm trạng thái loading/lỗi và tên tạm rỗng; hiện avatar bằng `ILRemoteImageView`, tải lại sau `avatar_url_expires_at`; nối EditProfile với `PATCH /v1/users/me`; thay số liệu mẫu khi có API thống kê.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
