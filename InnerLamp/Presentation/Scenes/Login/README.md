# Màn hình Đăng nhập (Login)

Feature `Login` — Clean Architecture + Coordinator + MVVM, theo đúng khuôn mẫu `Onboarding`
(xem `InnerLamp/Core/Base/README.md`), đối chiếu lại với thiết kế thật trong
`InnerLamp/Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html` (block `isLogin`) —
đăng nhập chỉ bằng **số điện thoại + mật khẩu**, không có email.

## Sơ đồ điều hướng (tổng thể)

```
AppCoordinator
  └─ showLogin()
       ILLoginCoordinator
         setViewControllers([ILLoginViewController]) — Login là root của stack riêng
         (bấm "Tạo tài khoản mới") → loginDidRequestSignup → AppCoordinator.showSignUp()
         (bấm "Quên?" cạnh mật khẩu) → loginDidRequestForgotPassword (chưa có màn ForgotPassword)
         (đăng nhập thành công) → loginDidFinishLogin (chưa có luồng Home trong scope hiện tại)
```

`ILLoginCoordinator` được `AppCoordinator` sở hữu vì đây là chuyển tiếp **cross-section**
(Onboarding/SignUp ↔ Login ↔ Home), theo đúng quy tắc trong
`.claude/skills/il-screen-builder/references/coordinator_navigation_rules.md`.

## Các file đã sinh / sửa

| Layer | File |
|---|---|
| Entity | `Domain/Entities/ILLoginEntity.swift` → `ILLoginEntity` (pure business fields only — no `*Error`/`isSubmitting`) |
| State model | `Presentation/Scenes/Login/ILLoginStateModel.swift` → `ILLoginStateModel` |
| UseCase | `Domain/UseCases/Login/ILLoginUseCase.swift` → `ILLoginUseCase` / `ILLoginUseCaseImpl` |
| Coordinator | `Presentation/Scenes/Login/ILLoginCoordinator.swift` → `ILLoginCoordinator` + `ILLoginCoordinatorDelegate` |
| ViewModel | `Presentation/Scenes/Login/ILLoginViewModel.swift` → `ILLoginViewModel` + `ILLoginNavEvent` |
| ViewController | `Presentation/Scenes/Login/ILLoginViewController.swift` → `ILLoginViewController` |
| Tests | `InnerLampTests/ILLoginViewModelTests.swift` → `ILLoginViewModelTests` + `MockILLoginUseCase` |

Component Design System mới (generic, không có nội dung riêng của Login, nên đặt ở
`Presentation/Common/DesignSystem/Components/` chứ không phải `Scenes/Login/Views/`):

| Component | Vì sao thêm |
|---|---|
| `ILDividerRow` | Hàng chia "hoặc" giữa CTA SMS và CTA tạo tài khoản — hai gạch ngang co giãn quanh nhãn giữa, chỉ phụ thuộc `text`, thay cho hàm private `makeDividerRow()` từng lặp nội bộ trong `ILLoginViewController`. |

Không có component feature-scoped mới nào (mọi field/CTA của Login đều tái dùng
`ILPhoneField`/`ILField`/`ILButton`/`ILLampGlowView`/`ILCountryPickerViewController` sẵn có từ
SignUp).

Wiring: `DIContainer` (`makeLoginUseCase/ViewModel/Coordinator`) + `AppCoordinator`
(`showLogin()` + conform `ILLoginCoordinatorDelegate`) — không đổi, đã nối sẵn từ trước.
Không file nào trong `InnerLamp/Core/Base/` bị sửa. Không thêm transition riêng — dùng
`CrossFadeTransition` mặc định.

## Luồng dữ liệu & logic màn hình

### 1. Vào màn hình

`ILLoginCoordinator.start()` tạo `ILLoginViewModel` qua `DIContainer`, subscribe
`viewModel.navigationEventPublisher` (Combine `.sink`, lưu vào `cancellables` của coordinator),
tạo `ILLoginViewController(viewModel:)` rồi `navigationController.setViewControllers([...])`
(Login là root của stack riêng, không push).

`ILLoginViewController.bindViewModel()` dựng `Input` từ các `PassthroughSubject` riêng của từng
trigger (xem danh sách ở khai báo property), gọi `viewModel.transform(input:)`, subscribe
`output.state` (`.receive(on: .main)`) vào `render(state:)`, rồi `viewDidLoadSubject.send(())`
ngay trong cùng lệnh gọi đồng bộ (Publisher không phát lại giá trị gửi trước khi có subscriber).

### 2. Người dùng tương tác với field

Mỗi thao tác UI gửi giá trị lên `*Subject` riêng của nó (không gọi thẳng `viewModel.handle*()` —
`transform(input:)` đã subscribe các `Input` publisher tương ứng ở phía ViewModel):

- **Số điện thoại**: bấm cờ/mã vùng (`ILPhoneField.onCountryTap`) → present
  `ILCountryPickerViewController`; chọn xong → gửi `countryChangedSubject`. Gõ số → gửi
  `phoneChangedSubject` mỗi ký tự (chỉ xoá lỗi field, không render lại — tránh set lại
  `ILField.text` trong lúc đang gõ, dễ làm nhảy con trỏ).
- **Mật khẩu**: gửi `passwordChangedSubject` mỗi ký tự (cùng lý do trên). Bấm "Quên?" cạnh
  mật khẩu → gửi `forgotPasswordTappedSubject`.
- `onReturn` chuyển focus: `Số điện thoại → Mật khẩu → bấm "Đăng nhập"`.

### 3. Bấm "Đăng nhập"

`ILLoginViewController.handleSubmitTapped()` → `view.endEditing(true)` rồi gửi
`submitTappedSubject`. ViewModel xử lý trong `handleSubmit()` (subscribe từ `input.submitTapped`):

1. Guard `!isSubmitting` (chặn double-tap).
2. Validate đồng bộ `phone`/`password` qua `useCase.validateXxx` — mỗi hàm trả `String?`
   (message đã `.localized`, hoặc `nil`).
3. Nếu còn lỗi → gửi state ngay, dừng lại; `updateUI` set `ILField.fieldState = .error(message)`
   cho field tương ứng.
4. Nếu hợp lệ → `isSubmitting = true`, gửi state ngay (nút chuyển `.loading`, "Đang đăng
   nhập…"), spawn `Task` gọi `useCase.login(phone:password:)` — `phone` truyền vào là
   `currentState.phoneE164` (mã vùng + số cách nhóm 3 chữ số).
5. **Thành công**: `isSubmitting = false`, gửi state, gửi
   `navigationEventSubject.send(.didLoginSuccessfully)`.
6. **Thất bại**: `isSubmitting = false`, `submitError = error.localizedDescription`, gửi state
   → `updateUI` gọi `showError(...)` (alert kế thừa từ `BaseViewController`). Không phát nav
   event, ở lại màn hình để sửa.

### 4. `ILLoginUseCaseImpl.login` làm gì (tạm thời)

Chưa có Auth API thật (`Core/Networking/` mới có khung `NetworkService`/`Endpoint`, chưa có
endpoint đăng nhập cụ thể). Đây là network call — nằm ngoài phạm vi `il-screen-builder` implement
thật (xem `references/data_layer_boundaries.md`), nên hàm hiện chỉ là stub một dòng
`print("TODO: implement login — network/repository call, not built by il-screen-builder")`,
không đọc/ghi Keychain, không tự giả lập lỗi `ILLoginError.invalidCredentials`.

**TODO khi có backend thật**: thay thân hàm bằng
`networkService.request(endpoint: LoginEndpoint(...))`; inject `NetworkService` cần thiết vào
`ILLoginUseCaseImpl.init` lúc đó (hiện không inject gì vì chưa có logic thật nào cần).

### 5. Điều hướng ra khỏi màn hình

`ILLoginViewModel.navigationEventPublisher` (được `ILLoginCoordinator.start()` subscribe qua
Combine `.sink`) xử lý 3 case của `ILLoginNavEvent`:

- **`.goToSignup`** (bấm "Tạo tài khoản mới") → coordinator gọi
  `delegate?.loginDidRequestSignup(self)` rồi `finish()`. `AppCoordinator` nhận qua
  `ILLoginCoordinatorDelegate.loginDidRequestSignup` → `showSignUp()` (đã nối thật).
- **`.goToForgotPassword`** (bấm "Quên?") → coordinator gọi
  `delegate?.loginDidRequestForgotPassword(self)` (không `finish()` — Login dùng
  `setViewControllers`, vẫn là root của stack, màn Forgot sẽ được push lên trên; `finish()` ở đây
  sẽ làm coordinator bị dealloc trong khi Login VC còn sống bên dưới). `AppCoordinator` hiện
  chưa có màn ForgotPassword thật để push — ngoài scope hiện tại.
- **`.didLoginSuccessfully`** (đăng nhập thành công) → coordinator gọi
  `delegate?.loginDidFinishLogin(self)` rồi `finish()`. `AppCoordinator` hiện chưa có luồng Home
  thật để điều hướng sang — ngoài scope hiện tại.

## Đối chiếu với thiết kế (`InnerLamp Prototype.dc.html`, block `isLogin`)

| Design | Implementation |
|---|---|
| Tiêu đề Lora 29px + phụ đề | `ILTypography.authTitle` + `login.title`/`login.subtitle` |
| Field "Số điện thoại" — cờ + mã vùng + mũi tên, dấu tick hợp lệ | `ILPhoneField` + `ILCountryPickerViewController` (cùng 12 quốc gia với SignUp) |
| Field "Mật khẩu" + link "Quên?" | `passwordField` (secure + `onTrailingTap`) |
| CTA "Đăng nhập" + "Đăng nhập bằng mã SMS" | `loginButton` + `smsCodeButton` |
| Hàng chia "hoặc" + CTA "Tạo tài khoản mới" + "Xem trước, đăng nhập sau" ghim đáy màn, phần trên cuộn riêng | `footerContainer` (ghim theo `view.keyboardLayoutGuide.topAnchor`) + `ILDividerRow` |

Điểm design có nhưng **chưa** làm (ngoài phạm vi hiện tại):

- "Đăng nhập bằng mã SMS" (`smsCodeButton`) chưa điều hướng sang màn Xác thực OTP riêng —
  `handleSmsCodeTapped()` là TODO, chờ `ILOtpCoordinator` hỗ trợ luồng đăng nhập (hiện `Otp` chỉ
  phục vụ xác thực sau khi Đăng ký).
- "Xem trước, đăng nhập sau" (`guestPreviewButton`) chưa vào được luồng Home — `TODO`, chờ có
  luồng Home.
- Màn Quên mật khẩu chưa tồn tại — `loginDidRequestForgotPassword` hiện không có action thật ở
  `AppCoordinator`.

## Việc còn để trống (TODO có chủ đích)

- `ILLoginUseCaseImpl.login`: stub `print("TODO: ...")` — chờ Auth API thật, không implement
  Keychain mock (đúng hard rule "never a guessed real implementation" của `il-screen-builder`).
  **Hệ quả**: nút "Đăng nhập" hiện luôn thành công (không throw `ILLoginError.
  invalidCredentials`) cho tới khi có implementation thật.
- `handleSmsCodeTapped()`/`handleGuestPreviewTapped()`: TODO cục bộ trong `ILLoginViewController`,
  không đi qua `ILLoginViewModel` vì chưa có logic/nav event nào cần xử lý — sẽ chuyển thành
  `Input` publisher riêng khi có luồng thật để nối.

## Changelog

- Rà soát lại theo `.claude/skills/il-screen-builder/SKILL.md` sau khi feature này được viết
  trước khi có skill (predate rule, giống `Onboarding`) — các điểm không khớp hard rule được sửa:
  1. `ILLoginStateModel` từng bị đặt nhầm ở `Domain/Entities/ILLoginModel.swift` (Presentation
     state model nằm trong Domain) — chuyển đúng vị trí
     `Presentation/Scenes/Login/ILLoginStateModel.swift`, xoá file cũ.
  2. Tách `ILLoginEntity` (pure business fields: `phone`, `password`) ra
     `Domain/Entities/ILLoginEntity.swift` — trước đó Domain không có Entity riêng, chỉ có
     StateModel bị đặt nhầm.
  3. `ILLoginUseCaseImpl.login` trước đó gọi thẳng `KeychainService`/`UserDefaultsService` để
     mô phỏng so khớp "đăng ký xong đăng nhập lại" — đây là local Repository call mà
     `il-screen-builder` không bao giờ được implement thật (xem
     `references/data_layer_boundaries.md`). Đưa về đúng dạng stub một dòng
     `print("TODO: ...")`, bỏ `keychainService`/`userDefaultsService` khỏi
     `ILLoginUseCaseImpl.init` và khỏi `DIContainer.makeLoginUseCase()` (cùng thay đổi đã áp dụng
     cho `ILSignUpUseCaseImpl` trước đó, xem `SignUp/README.md`).
  4. Migrate `ILLoginViewModel`/`ILLoginViewController`/`ILLoginCoordinator` từ shape
     closure-callback cũ (`onState:`/`onNavigationEvent`) sang Combine `Input`/`Output` +
     `navigationEventPublisher` — khớp `references/mvvm_pattern.md`. Mỗi subview vẫn là
     `private lazy var`/`let` cấu hình trong closure khởi tạo, `setupViews()` chỉ `addSubview` +
     wire action target vào `*Subject`.
  5. Tách hàm private `makeDividerRow()` (lặp lại logic 2 gạch + nhãn giữa) thành component dùng
     chung `ILDividerRow` (`Presentation/Common/DesignSystem/Components/`) — generic, không có
     nội dung riêng của Login, đúng quy tắc §3 `references/naming_conventions.md`.
  6. Thêm `ILLoginViewModelTests` (7 test, mock `ILLoginUseCase` thủ công, drive qua `Input`
     publisher) — trước đó feature này chưa có test nào.
  7. Thêm `README.md` này — trước đó feature chưa có.
