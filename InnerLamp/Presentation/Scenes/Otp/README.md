# Otp

<!--
Generated/maintained per il-screen-builder. This is a living status doc for this screen, not a
one-time scaffold artifact — update it (don't recreate it) whenever this feature's files change.
-->

## Overview

Màn xác thực mã OTP 6 số gửi tới số điện thoại người dùng vừa nhập ở SignUp (hoặc chọn kênh
"điện thoại" ở ForgotPassword). Được `ILOtpCoordinator` push lên trên stack hiện tại (SignUp/
ForgotPassword VC vẫn còn bên dưới); xác thực thành công báo `delegate` rồi `finish()`.

Spec: `Docs/Specs/Otp/` (requirements / design / tasks / changelog).

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILOtpTimingEntity.swift` | Done | `expiresInSeconds`, `resendAfterSeconds` — timing server trả về, dùng cho countdown + câu hạn mã. |
| Domain — UseCase | `ILOtpUseCase.swift` | Done | `getInitialState(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)`, `resendCode(phoneNumber:channel:) -> ILOtpTimingEntity`, `verifyCode(phoneNumber:code:)`. `verifyCode` lưu session (Keychain + `ILUserRepository`); `resendCode(.voiceCall)` ném `voiceCallUnsupported` không gọi mạng. Owns `ILOtpError` + `ILOtpPurpose` + `ILOtpOperation`. |
| Domain — Repository | `ILOtpRepository.swift` | Done | `verifyRegistrationOTP` -> `ILAuthSessionEntity`; `resendRegistrationOTP` -> `ILOtpTimingEntity`. |
| Data — Repository | `ILOtpRepositoryImpl.swift` | Done | Wrap `NetworkService`; map `NetworkError` -> `ILOtpError` (phân biệt verify/resend qua `operation`). |
| Data — DTO / Mapper | `ILOtpDTO.swift`, `Mappers/ILOtpMapper.swift` | Done | Request viết snake_case `CodingKeys`; response dựa `.convertFromSnakeCase`. |
| Data — Endpoints | `DataSources/Remote/VerifyRegistrationOTPEndpoint.swift`, `ResendOTPEndpoint.swift` | Done | `POST /v1/auth/register/verify-otp`, `POST /v1/auth/resend-otp`; `requiresAuth = false`. |
| Presentation — StateModel | `ILOtpStateModel.swift` | Done | `code`, lỗi (`codeError`/`resendError`), `isVerifying`, `isResending`, `secondsRemaining` + `otpExpiresInSeconds` (seed từ server). |
| Presentation — ViewModel | `ILOtpViewModel.swift` | Done | Combine `Input`/`Output`; countdown đếm lại từ timing server trả về; surface lỗi gửi lại. |
| Presentation — ViewController | `ILOtpViewController.swift` | Done | Câu hạn mã render từ `ILOtpStateModel.expiryText`. |
| Presentation — Coordinator | `ILOtpCoordinator.swift` | Done | Nhận và truyền timing ban đầu; forward `didVerify`. |
| Tests | `ILOtpViewModelTests.swift`, `ILOtpRepositoryTests.swift`, `ILOtpUseCaseTests.swift` | Done | ViewModel (11, mock UseCase); repository (26: error mapping, mapper, wire shapes); UseCase (5: session persistence trên Keychain + Core Data in-memory thật). |
| Wiring | `DIContainer` + `AppCoordinator` | Done | `makeOtpRepository()`/`makeOtpUseCase()`/`makeOtpViewModel(phoneNumber:otpExpiresInSeconds:resendAfterSeconds:)`/`makeOtpCoordinator(...)`. |

## Navigation events

- `.goBack` — bấm back trên header hoặc "Đổi số": pop về màn trước (SignUp/ForgotPassword), coordinator OTP `finish()`.
- `.didVerify(phoneNumber:)` — xác thực thành công: báo `delegate.otpDidVerify(_:phoneNumber:)` rồi `finish()`; `AppCoordinator` chuyển vào màn chính.

## Timing

Countdown "Gửi lại" và câu "Mã có hiệu lực trong …" lấy từ server (`resend_after_seconds` /
`expires_in_seconds`), không còn hardcode 47s / "10 phút". Timing ban đầu do SignUp truyền qua
`.didRequestVerification`; mỗi lần gửi lại lấy timing mới từ response `resend-otp`.

## Known gaps / not implemented yet

- Nhận mã qua **cuộc gọi thoại** chưa có backend (hợp đồng `resend-otp` không có tham số kênh):
  bấm banner hiện alert "chưa khả dụng", không gọi mạng. Xem ⚠️ trong `Docs/Specs/Otp/requirements.md`.
- `user.created_at` không được lưu (`ILUserEntity` / Core Data không mô hình field này).
- Token refresh (`POST /v1/auth/refresh`) chưa có; `refresh_token` đã được lưu để dùng sau.
- Không có UI test — chưa được yêu cầu.

## Changelog

- 2026-09-23 — tích hợp API thật: `verifyCode` gọi `POST /v1/auth/register/verify-otp` và lưu
  session (access/refresh token vào Keychain, user qua `ILUserRepository`); `resendCode` gọi
  `POST /v1/auth/resend-otp`; countdown/expiry theo timing server; voice-call để dành. Thêm
  `ILOtpRepository`/`ILOtpRepositoryImpl`, DTO/Mapper/Endpoints, `ILOtpTimingEntity`,
  `ILOtpRepositoryTests`, `ILOtpUseCaseTests`; `ILOtpViewModelTests` cập nhật. Spec: `Docs/Specs/Otp/`.
- 2026-09-15 — sửa vi phạm hard scope limit trong `references/data_layer_boundaries.md`:
  `ILOtpUseCaseImpl` trước đó tự sinh/lưu/so khớp mã OTP qua `KeychainService` (một local
  Repository call, lẽ ra phải là stub một-dòng-TODO chứ không được implement thật kể cả dạng
  mock). Đã đổi `resendCode`/`verifyCode` thành stub TODO đúng chuẩn; `getInitialState` chỉ còn
  gán `phoneNumber`, bỏ hẳn side-effect ghi Keychain. Cập nhật `DIContainer.makeOtpUseCase()` bỏ
  tham số `keychainService` không còn cần.
- 2026-09-14 — refactor toàn bộ scene sang đúng chuẩn `il-screen-builder`: ViewModel/Coordinator
  chuyển từ closure-callback sang Combine (`Input`/`Output` publisher, `navigationEventPublisher`);
  tách `ILOtpVoiceCallBannerView`/`ILOtpResendRowView` khỏi `ViewController`; subview chuyển sang
  `private lazy var`; thêm `ILOtpViewModelTests.swift`; thêm README này.
