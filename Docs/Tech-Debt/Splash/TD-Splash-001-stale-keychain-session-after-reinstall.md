---
id: TD-Splash-001
title: Keychain session survives app deletion, so a reinstall can skip Onboarding
title_vi: Session trong Keychain còn lại sau khi xóa app, cài lại có thể bỏ qua Onboarding
feature: Splash
level: Medium
status: Resolved
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/Splash/ILSplashUseCase.swift:48
---

## Description / Mô tả
EN: `ILSplashUseCaseImpl.hasSession()` only checks that `access_token` exists in the Keychain. Keychain items outlive app deletion (they are `ThisDeviceOnly`, so not synced to iCloud, but still kept on the device), so a reinstall can find an old token and go straight to Main.
VI: `ILSplashUseCaseImpl.hasSession()` chỉ kiểm tra `access_token` có trong Keychain. Item Keychain vẫn còn sau khi xóa app (là `ThisDeviceOnly` nên không sync iCloud nhưng vẫn nằm trên máy), nên cài lại có thể thấy token cũ và vào thẳng Main.

## Why it was taken on / Lý do chấp nhận nợ
EN: Not part of the requested change; awaiting a decision from the owner.
VI: Ngoài phạm vi yêu cầu; chờ chủ dự án quyết định.

## Impact / Ảnh hưởng
EN: After reinstall the app is not treated as new; combined with TD-Core-001 an expired token cannot recover.
VI: Sau khi cài lại app không được coi là mới; cộng với TD-Core-001 thì token hết hạn không thể phục hồi.

## Proposed fix / Hướng xử lý
EN: Keep a `has_launched_before` flag in UserDefaults (deleted with the app). If it is missing at launch, delete the Keychain tokens, then set the flag.
VI: Lưu cờ `has_launched_before` trong UserDefaults (bị xóa cùng app). Nếu chưa có khi khởi động thì xóa token trong Keychain rồi đặt cờ.

## Resolution / Kết quả xử lý
EN: 2026-10-07 — `ILSplashUseCaseImpl.hasSession()` now checks a `has_launched_before` flag in UserDefaults first; if missing it deletes both Keychain tokens and sets the flag. Side effect: a dev build installed before this change has no flag, so it is signed out once on the first launch after updating. Covered by `ILSplashUseCaseTests` (not yet run, see TD-Core-001).
VI: 2026-10-07 — `ILSplashUseCaseImpl.hasSession()` giờ kiểm tra cờ `has_launched_before` trong UserDefaults trước; nếu chưa có thì xóa cả hai token Keychain rồi đặt cờ. Tác dụng phụ: bản dev cài trước thay đổi này chưa có cờ nên bị đăng xuất một lần ở lần mở đầu tiên sau khi cập nhật. Có test `ILSplashUseCaseTests` (chưa chạy, xem TD-Core-001).
