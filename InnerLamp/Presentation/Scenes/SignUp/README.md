# Màn hình Đăng ký tài khoản (SignUp)

Feature `SignUp` — Clean Architecture + Coordinator + MVVM, theo đúng khuôn mẫu `Onboarding`
(xem `InnerLamp/Core/Base/README.md`). Tự sinh bởi skill `il-screen-builder`, đối chiếu lại với
thiết kế thật trong `InnerLamp/Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
(block `isSignup`) — bản đầu tiên (email + confirm password) đã bị thay hoàn toàn vì không khớp
thiết kế: thiết kế dùng **số điện thoại + OTP**, không phải email/password thuần.

## Sơ đồ điều hướng (tổng thể)

```
AppCoordinator
  └─ showOnboarding()
       OnboardingCoordinator
         (bấm "Bắt đầu" ở step cuối / "Bỏ qua")
         └─ onboardingDidRequestSignup → AppCoordinator.showSignUp()
              ILSignUpCoordinator
                push ILSignUpViewController lên navigationController hiện tại
                (bấm "Gửi mã xác thực") → signUpDidRequestVerification(phoneNumber:)
                  → AppCoordinator.showOtp(phoneNumber:) (đã nối, xem `Otp/README.md`)
                (bấm "Tôi đã có tài khoản") → signUpDidRequestLogin
                  → AppCoordinator.showLogin() (đã nối, xem `Login/README.md`)
```

`ILSignUpCoordinator` được `AppCoordinator` sở hữu vì đây là chuyển tiếp **cross-section**
(Onboarding → Signup), theo đúng quy tắc trong
`.claude/skills/il-screen-builder/references/coordinator_navigation_rules.md`.

## Các file đã sinh / sửa

| Layer | File |
|---|---|
| Entity | `Domain/Entities/ILSignUpEntity.swift` → `ILSignUpEntity` (pure business fields only — no `*Error`/`isSubmitting`) |
| State model | `Presentation/Scenes/SignUp/ILSignUpStateModel.swift` → `ILSignUpStateModel`, `ILPasswordStrength` |
| UseCase | `Domain/UseCases/SignUp/ILSignUpUseCase.swift` → `ILSignUpUseCase` / `ILSignUpUseCaseImpl` |
| Coordinator | `Presentation/Scenes/SignUp/ILSignUpCoordinator.swift` → `ILSignUpCoordinator` + `ILSignUpCoordinatorDelegate` |
| ViewModel | `Presentation/Scenes/SignUp/ILSignUpViewModel.swift` → `ILSignUpViewModel` + `ILSignUpNavEvent` |
| ViewController | `Presentation/Scenes/SignUp/ILSignUpViewController.swift` → `ILSignUpViewController` |
| View (feature-scoped) | `Presentation/Scenes/SignUp/Views/ILDharmaNameSuggestionField.swift` → `ILDharmaNameSuggestionField` |
| Tests | `InnerLampTests/ILSignUpViewModelTests.swift` → `ILSignUpViewModelTests` + `MockILSignUpUseCase` |

Component Design System mới (generic, không có nội dung riêng của SignUp, nên đặt ở
`Presentation/Common/DesignSystem/Components/` chứ không phải `Scenes/SignUp/Views/`):

| Component | Vì sao thêm |
|---|---|
| `ILCheckboxRow` | Ô tick "Tôi đồng ý điều khoản..." — chỉ phụ thuộc `text` + `isChecked`, tái dùng được cho mọi màn cần checkbox (điều khoản, ghi nhớ đăng nhập...). |
| `ILStrengthMeterView` | Thanh đo N-segment + nhãn (dùng cho độ mạnh mật khẩu) — chỉ phụ thuộc số segment/label/màu, tái dùng được cho các thước đo khác nếu cần. |
| `ILField.onTrailingTap` (mở rộng component có sẵn) | Cho phép bấm vào `trailingText` (nút "Hiện/Ẩn" mật khẩu) — trước đó `trailingText` chỉ là label tĩnh. |
| `ILTypography.authTitle` (thêm token) | Lora 29px — đúng size tiêu đề các màn xác thực (Đăng ký/OTP/Đăng nhập) trong design handoff, chưa có preset nào khớp. |
| `ILCountry` | Model + danh sách 12 quốc gia (khớp `Component.COUNTRIES` trong design handoff) cho bộ chọn mã vùng — dữ liệu tham chiếu UI thuần, tái dùng được ở Login/ForgotPassword khi các màn đó được đối chiếu lại thiết kế. |
| `ILPhoneField` | Ô số điện thoại kèm chọn mã vùng (cờ + mã quay số + mũi tên) + dấu tick hợp lệ + hint động — thay cho `ILField` không hỗ trợ mã vùng, khớp field "Số điện thoại" trong design handoff. |
| `ILCountryPickerViewController` | Bottom sheet chọn quốc gia (tìm kiếm + danh sách cờ/tên/mã) — trình bày qua `present(_:)` trực tiếp, không qua Coordinator vì không có state/luồng riêng cần theo dõi. |

Component feature-scoped mới (nội dung gắn chặt với luồng Đăng ký — pháp danh gợi ý sẵn từ
`ILSignUpUseCase`, không phải input tự do — nên đặt ở `Scenes/SignUp/Views/`):

| Component | Vì sao thêm |
|---|---|
| `ILDharmaNameSuggestionField` | Hàng "Pháp danh hoặc tên gọi" — giá trị + nút "Gợi ý" xoay vòng đổi tên, khớp đúng field không có `<input>` trong design handoff (trước đó bị code sai thành `ILField` nhập tự do). |

Wiring: `DIContainer` (`makeSignUpUseCase/ViewModel/Coordinator`) + `AppCoordinator`
(`showSignUp()` + conform `ILSignUpCoordinatorDelegate`). Không file nào trong
`InnerLamp/Core/Base/` bị sửa. Không thêm transition riêng — dùng `CrossFadeTransition` mặc định.

## Luồng dữ liệu & logic màn hình

### 1. Vào màn hình

`ILSignUpCoordinator.start()` tạo `ILSignUpViewModel` qua `DIContainer`, subscribe
`viewModel.navigationEventPublisher` (Combine `.sink`, lưu vào `cancellables` của coordinator),
tạo `ILSignUpViewController(viewModel:)` rồi `navigationController.pushViewController(...)`.

`ILSignUpViewController.bindViewModel()` dựng `Input` từ các `PassthroughSubject` riêng của từng
trigger (xem danh sách ở khai báo property), gọi `viewModel.transform(input:)`, subscribe
`output.state` (`.receive(on: .main)`) vào `render(state:)`, rồi `viewDidLoadSubject.send(())`
ngay trong cùng lệnh gọi đồng bộ (Publisher không phát lại giá trị gửi trước khi có subscriber).
`render` → `updateUI(with:)` set 3 field về `.normal`, thước đo mật khẩu ẩn (chưa gõ gì), checkbox
chưa tick, nút CTA ở trạng thái `.disabled` (đúng hành vi thiết kế: nút chỉ "sáng" khi tick điều
khoản).

### 2. Người dùng tương tác với field

Mỗi thao tác UI gửi giá trị lên `*Subject` riêng của nó (không gọi thẳng `viewModel.handle*()` —
`transform(input:)` đã subscribe các `Input` publisher tương ứng ở phía ViewModel):

- **Pháp danh/tên gọi**: KHÔNG phải ô nhập tự do (đúng thiết kế — field này không có `<input>`).
  Bấm nút "Gợi ý" trên `ILDharmaNameSuggestionField` → gửi `suggestDisplayNameTappedSubject` →
  ViewModel xoay vòng qua `useCase.dharmaNameSuggestions` (10 pháp danh, khớp `NAMES` trong design
  handoff) và gửi state mới.
- **Số điện thoại**: bấm cờ/mã vùng (`ILPhoneField.onCountryTap`) → `handleCountryTap()` present
  `ILCountryPickerViewController` (tìm kiếm không dấu + danh sách 12 quốc gia); chọn xong → gửi
  `countryChangedSubject` → ViewModel set `selectedCountry`, gửi state mới (đổi cờ/mã vùng/hint).
  Gõ số → gửi `phoneNumberChangedSubject` mỗi ký tự vì dấu tick hợp lệ + hint động
  (`isPhoneValid`/`phoneHint`) cần cập nhật theo thời gian thực đúng thiết kế
  (`phoneOk`/`phoneHint` trong `renderVals()`) — an toàn vì `updateUI` không bao giờ set lại
  `ILPhoneField.text`.
- **Mật khẩu**: gửi `passwordChangedSubject` mỗi ký tự, vì `ILStrengthMeterView` cần cập nhật độ
  mạnh mật khẩu theo thời gian thực (đúng thiết kế — 3 vạch + nhãn "Yếu/Khá tốt/Mạnh"). An toàn vì
  `updateUI` không bao giờ set lại `.text` của bất kỳ field nào — chỉ đồng bộ phần hiển thị phái
  sinh (lỗi, thước đo, trạng thái nút, checkbox).
- Bấm biểu tượng "Hiện"/"Ẩn" (`ILField.onTrailingTap`) → gửi `togglePasswordVisibilityTappedSubject`
  (VC tự giữ/khôi phục `isFirstResponder` quanh lần gửi này — mối quan tâm bàn phím thuần UI,
  không thuộc ViewModel), `updateUI` set `innerTextField.isSecureTextEntry` + đổi chữ trailing.
- Bấm hàng checkbox → gửi `toggleTermsTappedSubject`, `updateUI` cập nhật
  `ILCheckboxRow.isChecked` và bật/tắt nút CTA (`isSubmitEnabled`).
- `onReturn` chuyển focus: `Số điện thoại → Mật khẩu → bấm submit` (Pháp danh không có bàn phím
  nên không nằm trong chuỗi này).

### 3. Bấm "Gửi mã xác thực"

`ILSignUpViewController.handleSubmitTapped()` → `view.endEditing(true)` rồi gửi
`submitTappedSubject`. ViewModel xử lý trong `handleSubmit()` (subscribe từ `input.submitTapped`):

1. Guard `!isSubmitting && didAcceptTerms` (chặn double-tap và chặn gọi khi chưa tick điều
   khoản — phòng khi có Input khác vô tình kích submit, dù UI đã disable nút).
2. Validate đồng bộ `displayName`/`phoneNumber`/`password` qua `useCase.validateXxx` — mỗi hàm
   trả `String?` (message đã `.localized`, hoặc `nil`). Số điện thoại validate theo
   `nationalDigits.count >= selectedCountry.nationalDigitCount` — tổng quát theo quốc gia đang
   chọn, không còn cố định theo VN như bản trước.
3. Nếu còn lỗi → `stateSubject.send(.success(currentState))` ngay, dừng lại; `updateUI` set
   `ILField.fieldState = .error(message)` cho field tương ứng.
4. Nếu hợp lệ → `isSubmitting = true`, gửi state ngay (nút chuyển `.loading`, "Đang gửi mã…"),
   spawn `Task` gọi `useCase.sendVerificationCode(displayName:ordinationPlace:phoneNumber:email:password:)` —
   `phoneNumber` truyền vào là `currentState.phoneE164` (mã vùng + số cách nhóm 3 chữ số), không
   phải chuỗi số thô người dùng gõ.
5. **Thành công**: `isSubmitting = false`, gửi state, gửi
   `navigationEventSubject.send(.didRequestVerification(phoneNumber:))` với cùng `phoneE164` đó —
   khớp `phoneE164()` trong design handoff, để màn OTP hiển thị đúng "Đã gửi tới +84 912 345 678".
6. **Thất bại** (`ILSignUpError.phoneAlreadyRegistered`): `isSubmitting = false`,
   `submitError = error.localizedDescription`, gửi state → `updateUI` gọi `showError(...)`
   (alert kế thừa từ `BaseViewController`). Không phát nav event, ở lại màn hình để sửa.

### 4. `ILSignUpUseCaseImpl.sendVerificationCode` làm gì (tạm thời)

Chưa có Auth API thật (`Core/Networking/` mới có khung `NetworkService`/`Endpoint`, chưa có
endpoint gửi OTP cụ thể), cũng chưa có SMS provider. Đây là local Repository call
(`NetworkService`/Keychain/UserDefaults) — nằm ngoài phạm vi `il-screen-builder` implement thật
(xem `references/data_layer_boundaries.md`), nên hàm hiện chỉ là stub một dòng
`print("TODO: implement sendVerificationCode — network/repository call, not built by
il-screen-builder")`, không đọc/ghi Keychain, không tự simulate lỗi
`ILSignUpError.phoneAlreadyRegistered`.

**TODO khi có backend thật**: thay thân hàm bằng
`networkService.request(endpoint: SendOTPEndpoint(...))`; inject `NetworkService`/Repository cần
thiết vào `ILSignUpUseCaseImpl.init` lúc đó (hiện không inject gì vì chưa có logic thật nào cần).
Việc tạo tài khoản thật sự dời sang UseCase của màn OTP sau khi xác thực mã đúng.

### 5. Điều hướng ra khỏi màn hình

`ILSignUpViewModel.navigationEventPublisher` (được `ILSignUpCoordinator.start()` subscribe qua
Combine `.sink`) xử lý 3 case của `ILSignUpNavEvent`:

- **`.goBack`** (bấm nút back trên `ILNavBar`) → coordinator `popViewController` rồi
  `finish()`.
- **`.goToLogin`** (bấm "Tôi đã có tài khoản") → coordinator gọi
  `delegate?.signUpDidRequestLogin(self)` rồi `finish()`. `AppCoordinator` nhận qua
  `ILSignUpCoordinatorDelegate.signUpDidRequestLogin` → `showLogin()` (đã nối thật).
- **`.didRequestVerification(phoneNumber:)`** (gửi OTP thành công) → coordinator gọi
  `delegate?.signUpDidRequestVerification(self, phoneNumber:)` (không `finish()` ở nhánh này —
  xem comment trong `ILSignUpCoordinator.start()`). `AppCoordinator` nhận qua
  `signUpDidRequestVerification` → `showOtp(phoneNumber:)` (đã nối thật, xem `Otp/README.md`).

## Đối chiếu với thiết kế (`InnerLamp Prototype.dc.html`, block `isSignup`)

| Design | Implementation |
|---|---|
| Header "Tạo tài khoản" | `signup.header.title` |
| Tiêu đề Lora 29px "Kết duyên cùng InnerLamp" | `ILTypography.authTitle` + `signup.title` |
| Field "Pháp danh hoặc tên gọi" — giá trị gợi ý + nút "Gợi ý" xoay vòng, KHÔNG có `<input>` | `ILDharmaNameSuggestionField` + `useCase.dharmaNameSuggestions` (10 tên, khớp `NAMES`) |
| Field "Nơi xuất gia" (tuỳ chọn, `ordination_place`) — **không có trong design handoff**, thêm theo yêu cầu + `Docs/Specs/API/openapi.yaml` (`RequestOTPRequest.ordination_place`, nullable) | `ordinationPlaceField` (`ILField`, giữa pháp danh và số điện thoại) — nhập tự do, không validate, không chặn submit |
| Field "Số điện thoại" — cờ + mã vùng + mũi tên, dấu tick hợp lệ, hint động | `ILPhoneField` + `ILCountryPickerViewController` (12 quốc gia, khớp `Component.COUNTRIES`) |
| Field "Email" (tuỳ chọn, để nhận biên nhận cúng dường) — viền đỏ khi gõ sai định dạng, không chặn submit | `emailField` (`ILField`) + `ILSignUpStateModel.hasEmailValue`/`isEmailFormatValid` |
| Field "Mật khẩu" + toggle "Hiện" + thước đo 3 vạch | `passwordField` (secure + `onTrailingTap`) + `strengthMeter` |
| Checkbox điều khoản khoá nút CTA | `termsRow` (`ILCheckboxRow`) + `isSubmitEnabled` |
| CTA "Gửi mã xác thực" + "Tôi đã có tài khoản" ghim đáy màn, có viền ngăn cách, phần trên cuộn riêng | `footerContainer` (ghim theo `view.keyboardLayoutGuide.topAnchor`) + `footerDivider` |
| CTA "Gửi mã xác thực" → màn OTP | `submitButton` → `.didRequestVerification` |

Điểm design có nhưng **chưa** làm (ngoài phạm vi hiện tại):

- Link con trỏ trong text điều khoản ("Điều khoản sử dụng", "Chính sách quyền riêng tư") hiện là
  text tĩnh, chưa mở trang riêng — cần `NSAttributedString` + `UITextView`/tap-range detection,
  để lần sau nếu có yêu cầu riêng.

## Việc còn để trống (TODO có chủ đích)

- `ILSignUpUseCaseImpl.sendVerificationCode`: stub `print("TODO: ...")` — chờ Auth API + SMS
  provider thật, không implement Keychain mock (đúng hard rule "never a guessed real
  implementation" của `il-screen-builder`). **Hệ quả**: nút "Gửi mã xác thực" hiện đi thẳng vào
  màn OTP mà không có thao tác lưu/kiểm tra nào thật sự chạy phía sau; `ILSignUpError.
  phoneAlreadyRegistered` không còn được throw cho tới khi có implementation thật.
- `ILCountryPickerCell`/`ILDharmaNameSuggestionField`/`ILPhoneField`: vài `CAShapeLayer` phụ (mũi
  tên, dấu tick, viền pill) là `CGColor` tĩnh, chỉ `ILPhoneField`/`ILDharmaNameSuggestionField` tự
  refresh khi đổi light/dark qua `traitCollectionDidChange` — `ILCountryPickerCell` (dùng tạm thời
  trong lúc sheet mở) thì chưa, chấp nhận được vì sheet hiếm khi mở lúc đổi theme.

## Changelog

- Gom regex email về một nơi: `Domain/Validation/ILEmailValidator.swift` (`isValid(_:)`, trim
  khoảng trắng trước khi kiểm tra). `ILSignUpUseCaseImpl.validateEmail` và
  `ILSignUpStateModel.isEmailFormatValid` đều gọi vào đây thay vì mỗi nơi giữ một bản regex. Thêm
  `ILEmailValidatorTests` (3 test). Đồng bộ `Docs/Specs/SignUp/` lên v1.6 (email bắt buộc, mật khẩu
  ≥ 8, `ordination_place`).
- **Email bắt buộc + mật khẩu tối thiểu 8 ký tự** theo yêu cầu (đảo lại quyết định "email tuỳ chọn" ở
  mục changelog bên dưới — mục đó giờ chỉ còn giá trị lịch sử). Thêm `ILSignUpUseCase.validateEmail`
  (rỗng → `signup.error.emailRequired`, sai định dạng → `signup.error.emailInvalid`),
  `ILSignUpStateModel.emailError` (tính vào `hasValidationError` nên chặn submit),
  `ILSignUpViewModel.handleSubmit` validate email, `handleEmailChanged` xoá lỗi cũ; VC hiển thị
  `emailError` ưu tiên hơn kiểm tra live. Mật khẩu: `validatePassword` dùng
  `ILSignUpUseCaseImpl.minimumPasswordLength = 8` (cũng là mốc điểm đầu tiên của
  `passwordStrength`), cập nhật `signup.error.passwordTooShort` + placeholder. 4 test mới, các test
  submit hợp lệ cập nhật email + mật khẩu 8 ký tự. **Lưu ý**: `Login`/`ForgotPassword` chưa đổi
  quy tắc mật khẩu 6 ký tự cũ — cần đồng bộ nếu muốn thống nhất. Design handoff và
  `Docs/Specs/SignUp/*` vẫn mô tả email tuỳ chọn/mật khẩu 6 ký tự — chưa cập nhật.
- Thêm field tuỳ chọn **Nơi xuất gia** (`ordination_place`) theo yêu cầu — API `RequestOTPRequest` đã có
  sẵn field nullable này nhưng màn Đăng ký chưa thu thập. Thêm: `ILSignUpEntity.ordinationPlace`,
  `ILSignUpStateModel.ordinationPlace`, `Input.ordinationPlaceChanged` +
  `handleOrdinationPlaceChanged` (ViewModel), `ordinationPlaceField` (`ILField`, đặt ngay sau
  Pháp danh; return-key chain `Pháp danh → Nơi xuất gia → Số điện thoại`), tham số
  `ordinationPlace` trong `ILSignUpUseCase.sendVerificationCode` (đã trim khoảng trắng; rỗng nếu bỏ
  trống), 3 key `signup.field.ordinationPlace.*` trong `vi.json`, 3 test mới
  (`ILSignUpViewModelTests`). Field tuỳ chọn hoàn toàn nên không thêm `validateOrdinationPlace`.
  Giả định chưa xác nhận: nhãn UI/vị trí field/text hint (design handoff chưa có field này) — cần
  đối chiếu lại với designer. `sendVerificationCode` vẫn là stub — chưa gửi field này lên server
  thật; nối vào request OTP khi làm data layer (`il-data-layer-builder`).
- Đối chiếu lại với `InnerLamp Prototype.dc.html` (block `isSignup`, `emailRaw`/`onEmail`/
  `emailBd`/`emailOk`) theo yêu cầu kiểm tra UI — phát hiện field **Email** (tuỳ chọn, để nhận
  biên nhận cúng dường) có trong thiết kế + `README.md` gốc của design handoff (dòng mô tả màn
  `signup`) nhưng bị thiếu hoàn toàn khỏi implementation (mất khi bản email+confirm-password cũ
  bị gỡ để chuyển sang số điện thoại + OTP — xem đoạn mở đầu file này). Bổ sung: `ILSignUpEntity.
  email`, `ILSignUpStateModel.email`/`hasEmailValue`/`isEmailFormatValid`, `emailField` (`ILField`,
  giữa `phoneField` và `passwordField`, đúng thứ tự thiết kế), `ILSignUpViewModel.
  handleEmailChanged`, tham số `email` trong `ILSignUpUseCase.sendVerificationCode`. Theo đúng
  `signupNext` trong design handoff (chỉ kiểm tra `s.terms`), email sai định dạng CHỈ đổi viền đỏ
  + hiện lỗi `signup.error.emailInvalid`, KHÔNG chặn nút "Gửi mã xác thực" — khác với displayName/
  phone/password vốn chặn submit qua `hasValidationError`. Thêm 2 test (`ILSignUpViewModelTests`),
  cập nhật `MockILSignUpUseCase` theo chữ ký mới. Đồng bộ `Docs/Specs/SignUp/` (v1.5).
- Đối chiếu lại với `references/data_layer_boundaries.md` sau khi skill `il-screen-builder` cập
  nhật hard rule "`IL{{Feature}}Entity`/`IL{{Feature}}StateModel`/`IL{{Feature}}DTO` never merged"
  — 3 điểm được sửa: (1) tách `ILSignUpEntity` (pure business fields: `displayName`,
  `phoneNumber`, `password`) ra khỏi `Domain/Entities/ILSignUpModel.swift` cũ (file đó thực chất
  chỉ chứa `ILSignUpStateModel`/`ILPasswordStrength` — UI-only state bị đặt nhầm ở Domain); (2)
  chuyển `ILSignUpStateModel`/`ILPasswordStrength` sang đúng vị trí Presentation
  (`Presentation/Scenes/SignUp/ILSignUpStateModel.swift`); (3) xoá `Data/DTOs/SignUpDTO.swift` +
  `Data/DTOs/Mappers/SignUpMapper.swift` — không có `IL` prefix, map thẳng vào
  `ILSignUpStateModel` thay vì `Entity` (vi phạm "Mapper chỉ Entity<->DTO, không bao giờ đụng
  StateModel"), và chưa có API contract nào được xác nhận cho Auth nên theo quy tắc "đừng sinh
  DTO/Mapper speculatively 'for later'" — cả hai file coi như chết (không nơi nào gọi tới) và bị
  bỏ, sẽ sinh lại đúng chuẩn `ILSignUpDTO`/`ILSignUpMapper` khi có Auth API thật.
- **Rà soát lần 2, đúng theo yêu cầu**: `ILSignUpUseCaseImpl.sendVerificationCode` trước đó vẫn
  gọi thẳng `KeychainService` để mô phỏng lưu/kiểm tra "đã đăng ký" — đây chính là local
  Repository call mà `il-screen-builder` **không bao giờ** được implement thật, dù mục đích ban
  đầu là để `ILLoginUseCase` đọc lại (mô phỏng "đăng ký xong đăng nhập lại" khi chưa có Auth API).
  Đã đưa về đúng dạng stub một dòng `print("TODO: ...")`, xoá `keychainService`/
  `userDefaultsService`/`PendingSignUp`/`StorageKeys` không còn dùng tới khỏi
  `ILSignUpUseCaseImpl`, và bỏ 2 tham số đó khỏi `DIContainer.makeSignUpUseCase()`.
  **Side effect cần lưu ý**: luồng mock "đăng ký xong đăng nhập lại bằng đúng số điện
  thoại/mật khẩu vừa đăng ký" ở `ILLoginUseCase.login` (đọc key `signup_pending_credentials`)
  không còn hoạt động cho tới khi có Auth API thật — đây là hệ quả bắt buộc của việc tuân thủ
  đúng hard rule, chưa xử lý tiếp vì nằm ngoài phạm vi feature Login.
- Đối chiếu lại với `Docs/design_handoff_innerlamp/design/InnerLamp Prototype (standalone).html`
  (block `isSignup`) theo yêu cầu cập nhật skill `il-screen-builder` — 2 lệch lớn so với thiết kế
  được sửa: (1) field "Pháp danh" từng là `ILField` nhập tự do, đổi thành
  `ILDharmaNameSuggestionField` (giá trị gợi ý sẵn + nút xoay vòng, đúng thiết kế không có ô nhập
  tự do); (2) field "Số điện thoại" từng không có chọn mã vùng, đổi thành `ILPhoneField` +
  `ILCountryPickerViewController` (12 quốc gia). Đồng thời ghim CTA + "Tôi đã có tài khoản" ở đáy
  màn hình bằng `footerContainer`/`view.keyboardLayoutGuide` thay vì để trôi trong `scrollView`,
  và tổng quát hoá validate số điện thoại theo quốc gia đang chọn thay vì cố định theo VN.
- Migrate `ILSignUpViewModel`/`ILSignUpViewController`/`ILSignUpCoordinator` từ shape
  closure-callback cũ (`onState:`/`onNavigationEvent`) sang Combine `Input`/`Output` +
  `navigationEventPublisher` — khớp `references/mvvm_pattern.md` sau khi skill cập nhật (bản trước
  của màn này predate rule, xem `Onboarding` làm ví dụ canonical). Mỗi subview chuyển thành
  `private lazy var` cấu hình trong closure khởi tạo, `setupViews()` chỉ `addSubview` + wire action
  target vào `*Subject`. Thêm `ILSignUpViewModelTests` (13 test, mock `ILSignUpUseCase` thủ công,
  drive qua `Input` publisher) — trước đó feature này chưa có test nào.
