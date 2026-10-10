# Màn hình Quên mật khẩu (ForgotPassword)

<!--
Generated/rà soát theo `.claude/skills/ui-builder/SKILL.md`. Đây là tài liệu trạng thái
sống của màn hình này — cập nhật tại chỗ (không viết lại từ template) khi có thay đổi.
-->

## Overview

Feature `ForgotPassword` — Clean Architecture + Coordinator + MVVM, được `ILLoginCoordinator`
điều hướng tới khi bấm "Quên?" cạnh mật khẩu ở màn Đăng nhập. Người dùng chọn nhận hướng dẫn đặt
lại mật khẩu qua **số điện thoại** hoặc **email** đã đăng ký; gửi thành công thì mượn lại luồng
OTP xác thực số điện thoại đã có (giống SignUp → OTP), hoặc — nếu chọn email — hiện chưa có màn
xác thực riêng (ngoài scope hiện tại).

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILForgotPasswordEntity.swift` | Done | `fullPhone`/`fullEmail` — số điện thoại/email đã đăng ký (business fields thuần). |
| Presentation — StateModel | `ILForgotPasswordStateModel.swift` | Done | `method`, `selectedCountry`, `fullPhone` (gõ trực tiếp, không tải sẵn — người dùng chưa đăng nhập), `submitError`, `isSubmitting` + computed (`isPhoneValid`/`selectedContact`/`selectedFieldLabel`/`isSubmitEnabled`). |
| Data — DTO + Mapper | N/A | N/A (no confirmed API contract yet) | Chưa có Auth API thật cho luồng Quên mật khẩu. |
| Domain — UseCase | `ILForgotPasswordUseCase.swift` | Skeleton | `getInitialState()` trả entity rỗng (đúng — màn này không tải sẵn số của ai, người dùng tự gõ). `sendResetInstructions` là stub một dòng TODO (network call thật). |
| Presentation — ViewModel | `ILForgotPasswordViewModel.swift` | Done | 6 action: `viewDidLoad`, `methodChanged`, `phoneChanged`, `submitTapped`, `backTapped`, `backToLoginTapped` — Combine `Input`/`Output` + `navigationEventPublisher`. |
| Presentation — ViewController | `ILForgotPasswordViewController.swift` | Done | UI khớp prototype: dùng lại `ILPhoneField` (cùng control Đăng nhập/Đăng ký — cờ + mã vùng + `UITextField` thật, tap được để bật keyboard) thay vì thẻ hiển thị tĩnh; thêm hộp gợi ý đổi số điện thoại; CTA (`ILButton` + link "Trở lại đăng nhập") ghim đáy màn hình qua `bottomStack`. Bỏ `ILOptionCard` (không còn switcher phone/email trên UI) — `method` StateModel giữ nguyên mặc định `.phone` để không phá vỡ `ILForgotPasswordViewModel`/tests. |
| Presentation — Coordinator | `ILForgotPasswordCoordinator.swift` | Done | Cả 3 case của `ILForgotPasswordNavEvent` đều wired. |
| Tests | `ILForgotPasswordViewModelTests.swift` | Done | 9 test thật (mock `ILForgotPasswordUseCase` thủ công, drive qua `Input` publisher) — gồm `test_phoneChanged_updatesFullPhoneAndEnablesSubmit`. |
| Wiring | `DIContainer` + `AppCoordinator` | Done | `AppCoordinator` sở hữu (cross-section: Login ↔ ForgotPassword ↔ Otp), theo `references/coordinator_navigation_rules.md`. |

## Navigation events

- **`.goBack`** (bấm back trên header hoặc "Trở lại đăng nhập") → coordinator
  `popViewController` rồi `finish()`.
- **`.goToOtp(phoneNumber:)`** (gửi hướng dẫn thành công, phương thức = số điện thoại) →
  `delegate?.forgotPasswordDidRequestOtp` — `AppCoordinator` push `ILOtpCoordinator` (mượn lại
  luồng OTP xác thực đã có). Forgot VC vẫn đứng yên dưới OTP trên stack, không `finish()`.
- **`.didRequestEmailReset(email:)`** (gửi hướng dẫn thành công, phương thức = email) →
  `delegate?.forgotPasswordDidRequestEmailReset` — hiện `AppCoordinator` chỉ `print(...)`, chưa
  có màn xác thực đặt lại mật khẩu qua email trong scope hiện tại.

## Known gaps / not implemented yet

- `ILForgotPasswordUseCaseImpl.getInitialState()` không đọc Keychain nữa — nạp số điện
  thoại/email đã đăng ký là một local Repository call, ngoài scope thật của
  `ui-builder` (xem `references/data_layer_boundaries.md`). **Hệ quả**: 2 thẻ lựa chọn
  hiện trống cho tới khi có implementation thật; nút gửi hướng dẫn bị disable
  (`isSubmitEnabled == false`) vì `selectedContact` rỗng.
- `ILForgotPasswordUseCaseImpl.sendResetInstructions` — stub `print("TODO: ...")`, chờ Auth API
  thật (gửi SMS/email); không tự giả lập lỗi `ILForgotPasswordError.contactNotFound`.
- Xác thực đặt lại mật khẩu qua email (`didRequestEmailReset`) chưa có màn riêng — ngoài scope.
- Không có UI test — không được yêu cầu.

## Changelog

- 2026-09-15 — Rà soát lại theo `.claude/skills/ui-builder/SKILL.md` (feature này được
  viết trước khi skill tồn tại, giống `Onboarding`/`Login` trước khi sửa) — các điểm không khớp
  hard rule được sửa:
  1. `ILForgotPasswordStateModel` từng bị đặt nhầm ở
     `Domain/Entities/ILForgotPasswordModel.swift` (Presentation state model nằm trong Domain,
     lẫn cả UI-only field `isSubmitting`/`submitError`) — chuyển đúng vị trí
     `Presentation/Scenes/ForgotPassword/ILForgotPasswordStateModel.swift`, xoá file cũ.
  2. Tách `ILForgotPasswordEntity` (pure business fields: `fullPhone`, `fullEmail`) +
     `ILForgotPasswordMethod` ra `Domain/Entities/ILForgotPasswordEntity.swift` — trước đó Domain
     không có Entity riêng, chỉ có StateModel bị đặt nhầm. `maskedPhone`/`maskedEmail` chuyển
     thành computed property trên StateModel (display-only formatting) thay vì field lưu sẵn từ
     UseCase.
  3. `ILForgotPasswordUseCaseImpl.getInitialState()` trước đó gọi thẳng `KeychainService` để nạp
     số điện thoại vừa đăng ký — đây là local Repository call mà `ui-builder` không được
     phép implement thật (xem `references/data_layer_boundaries.md`, cùng cách xử lý đã áp dụng
     cho `ILLoginUseCaseImpl`/`ILSignUpUseCaseImpl`, xem `Login/README.md`). Đưa về trả
     `ILForgotPasswordEntity.empty`, bỏ `keychainService` khỏi `init` và khỏi
     `DIContainer.makeForgotPasswordUseCase()`.
  4. Migrate `ILForgotPasswordViewModel`/`ILForgotPasswordViewController`/
     `ILForgotPasswordCoordinator` từ shape closure-callback cũ (`onState:`/`onNavigationEvent`)
     sang Combine `Input`/`Output` + `navigationEventPublisher` — khớp
     `references/mvvm_pattern.md`. Mỗi subview chuyển thành `private lazy var` cấu hình trong
     closure khởi tạo; `setupViews()` chỉ `addSubview` + wire action target vào `*Subject`.
  5. Thêm `ILForgotPasswordViewModelTests` (8 test, mock `ILForgotPasswordUseCase` thủ công, drive
     qua `Input` publisher) — trước đó feature này chưa có test nào.
  6. Thêm `README.md` này — trước đó feature chưa có.
