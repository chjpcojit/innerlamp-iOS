---
id: TD-Profile-004
title: Logout ignores a failed server revoke
title_vi: Đăng xuất bỏ qua lỗi khi thu hồi phiên trên server
feature: Profile
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Profile/ILProfileUseCase.swift
---

## Description / Mô tả
EN: `ILProfileUseCaseImpl.logout()` calls `POST /v1/auth/logout` with `try?` and carries on clearing the local session whatever the outcome. The failure is neither logged nor retried, so an offline logout leaves the server-side session alive until its natural expiry, and nothing records that it happened.
VI: `ILProfileUseCaseImpl.logout()` gọi `POST /v1/auth/logout` bằng `try?` và vẫn xóa phiên cục bộ dù kết quả ra sao. Lỗi không được log hay thử lại, nên đăng xuất khi offline để phiên trên server sống đến khi hết hạn tự nhiên, và không có dấu vết nào ghi lại.

## Why it was taken on / Lý do chấp nhận nợ
EN: A user who asks to sign out must not be stuck signed in because the network is down; the refresh token is rotated on use and the access token is short-lived.
VI: Người dùng muốn đăng xuất không được kẹt lại vì mất mạng; refresh token bị xoay khi dùng và access token sống ngắn.

## Impact / Ảnh hưởng
EN: A leaked refresh token from before logout stays valid until it expires. No user-visible effect. Note: even on a successful revoke the backend keeps the old access token valid up to its 15-minute `exp` (no denylist), so it is only dropped locally.
VI: Refresh token bị lộ từ trước khi đăng xuất vẫn hợp lệ đến khi hết hạn. Người dùng không thấy ảnh hưởng. Lưu ý: kể cả revoke thành công, backend vẫn chấp nhận access token cũ đến hết hạn 15 phút (không có denylist), nên chỉ xóa được ở máy.

## Proposed fix / Hướng xử lý
EN: Log the failure through `LoggingService` and queue the revoke (keep the refresh token's `sid`/token in a pending-revoke store) to retry on the next launch or connectivity change.
VI: Log lỗi qua `LoggingService` và xếp hàng thu hồi (lưu token chờ thu hồi) để thử lại ở lần mở app sau hoặc khi có mạng.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
