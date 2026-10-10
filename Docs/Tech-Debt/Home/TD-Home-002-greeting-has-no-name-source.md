---
id: TD-Home-002
title: Home greeting has no name source
title_vi: Lời chào ở Home chưa có nguồn tên
feature: Home
level: Low
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Domain/UseCases/Home/ILHomeUseCase.swift:94
---

## Description / Mô tả
EN: `ILHomeUseCaseImpl.getInitialState()` leaves `displayName` empty, so the greeting always shows the "khách" fallback. It used to read a temporary Keychain item (`signup_pending_credentials`) that held name, phone and the plaintext password from an old mock sign-up; no code has written that item since before the first commit, so the greeting was already always "khách". The read and the struct were removed.
VI: `ILHomeUseCaseImpl.getInitialState()` để `displayName` rỗng nên lời chào luôn hiện "khách". Trước đây nó đọc một item Keychain tạm (`signup_pending_credentials`) chứa tên, số điện thoại và mật khẩu thô từ mock đăng ký cũ; không còn code nào ghi item đó từ trước commit đầu tiên, nên lời chào vốn đã luôn là "khách". Phần đọc và struct đã được gỡ.

## Why it was taken on / Lý do chấp nhận nợ
EN: Removing the plaintext-password read was a security cleanup; wiring the real user needs an async use-case/ViewModel change beyond that scope.
VI: Gỡ phần đọc mật khẩu thô là dọn dẹp bảo mật; nối user thật cần đổi use case/ViewModel sang async, ngoài phạm vi.

## Impact / Ảnh hưởng
EN: The greeting never shows the user's dharma name even though it is stored locally (`ILUserRepository.loadUser()`).
VI: Lời chào không bao giờ hiện pháp danh dù đã lưu cục bộ (`ILUserRepository.loadUser()`).

## Proposed fix / Hướng xử lý
EN: Inject `ILUserRepository` into the Home use case, add an async `loadDisplayName()` (dharma name, falling back to nothing) and update the greeting from the ViewModel after `viewDidLoad`, like `loadRandomVerse()`.
VI: Inject `ILUserRepository` vào use case Home, thêm `loadDisplayName()` async (pháp danh) và cập nhật lời chào từ ViewModel sau `viewDidLoad`, giống `loadRandomVerse()`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
