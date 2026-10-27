---
id: TD-Login-001
title: Forgot password stops after the request step
title_vi: Quên mật khẩu dừng sau bước yêu cầu
feature: Login
level: High
status: Open
created: 2026-10-27
updated: 2026-10-27
files:
  - InnerLamp/App/AppCoordinator.swift:210
---

## Description / Mô tả
EN: `AppCoordinator.forgotPasswordDidRequestOtp` no longer opens the code screen, because that screen is registration-only and reset by phone no longer exists in contract 3.0.0. The ForgotPassword scene is still the old print stub, so the flow ends after the user taps the request button.
VI: `AppCoordinator.forgotPasswordDidRequestOtp` không còn mở màn nhập mã, vì màn đó giờ chỉ cho đăng ký và đặt lại bằng số điện thoại không còn trong contract 3.0.0. Scene ForgotPassword vẫn là stub in log cũ, nên luồng dừng sau khi người dùng bấm nút gửi yêu cầu.

## Why it was taken on / Lý do chấp nhận nợ
EN: Reset by email code is a separate change (Login `tasks.md` Phase 5); the old path sent a phone reset to a registration screen and could never succeed.
VI: Đặt lại bằng mã email là thay đổi riêng (Login `tasks.md` Phase 5); đường cũ đưa reset bằng số điện thoại sang màn đăng ký nên vốn không thể thành công.

## Impact / Ảnh hưởng
EN: Users who forgot their password cannot reset it in the app until Phase 5 ships.
VI: Người quên mật khẩu chưa đặt lại được trong app cho tới khi Phase 5 xong.

## Proposed fix / Hướng xử lý
EN: Build Login `tasks.md` Phase 5 (`password-reset/request-otp` and `confirm`) and remove `forgotPasswordDidRequestOtp`.
VI: Làm Login `tasks.md` Phase 5 (`password-reset/request-otp` và `confirm`) và bỏ `forgotPasswordDidRequestOtp`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
