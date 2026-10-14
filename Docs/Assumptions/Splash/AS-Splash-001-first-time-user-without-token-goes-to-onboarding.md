---
id: AS-Splash-001
title: A user with no stored session who has not completed Onboarding goes to Onboarding, not Login
title_vi: User không có session và chưa hoàn thành Onboarding sẽ vào Onboarding, không vào Login
feature: Splash
level: Medium
status: Validated
created: 2026-10-10
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Splash/ILSplashViewModel.swift:80
source: Docs/Specs/Splash/requirements.md (FR-004, user said "no token or failed refresh → Login")
owner: Product / BA
---

## Assumption / Giả định
EN: The user's rule "no token → Login" applies to users who already completed Onboarding. A first-time user (fresh install, Onboarding not completed) still sees Onboarding first.
VI: Quy tắc "không còn token → Login" áp dụng cho user đã hoàn thành Onboarding. User mới (cài mới, chưa xong Onboarding) vẫn xem Onboarding trước.

## Rationale / Cơ sở giả định
EN: Sending every tokenless launch to Login would make Onboarding unreachable for new users. "Onboarding completed" is the existing `has_completed_onboarding` flag, which is erased with the app, so a reinstall also shows Onboarding.
VI: Nếu mọi lần mở app không có token đều vào Login thì user mới không bao giờ thấy Onboarding. "Đã onboard" dùng cờ `has_completed_onboarding` sẵn có, cờ này bị xóa cùng app nên cài lại cũng thấy Onboarding.

## Implications if wrong / Hệ quả nếu sai
EN: If product wants Login for every tokenless launch (including fresh installs), the first-run experience loses Onboarding. If Onboarding was skipped via a path that does not set the flag, a returning user would see Onboarding again.
VI: Nếu product muốn mọi lần không có token đều vào Login (kể cả cài mới) thì trải nghiệm lần đầu mất Onboarding. Nếu có đường bỏ qua Onboarding mà không set cờ, user quay lại sẽ thấy lại Onboarding.

## Validation / Cách xác nhận
EN: Ask Product / BA to confirm the first-time-user behavior. Verify on a device: finish Onboarding, log out, relaunch → Login; reinstall → Onboarding.
VI: Hỏi Product / BA xác nhận hành vi user mới. Kiểm tra trên máy thật: xong Onboarding, đăng xuất, mở lại → Login; cài lại → Onboarding.

## Outcome / Kết luận
EN: Update 2026-10-11 (user): a tokenless launch after Onboarding now goes to SignUp, not Login (a failed session refresh still goes to Login). Validated 2026-10-10 by the user: the first launch after install shows Onboarding, later launches do not; losing the session sends the user to Login. Remaining edge case: Onboarding is keyed on the completed flag, so a user who kills the app before finishing Onboarding sees it again on the next launch.
VI: Cập nhật 2026-10-11 (user): mở app không có token sau khi đã Onboarding giờ vào Đăng ký, không vào Đăng nhập (refresh session thất bại vẫn về Đăng nhập). Đã xác nhận 2026-10-10 bởi user: lần đầu mở sau khi cài thấy Onboarding, các lần sau không thấy; mất session thì về Đăng nhập. Trường hợp biên còn lại: Onboarding dựa trên cờ "đã hoàn thành", nên user thoát app giữa chừng sẽ thấy lại Onboarding ở lần mở sau.
