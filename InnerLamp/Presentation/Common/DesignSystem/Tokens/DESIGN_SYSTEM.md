# InnerLamp Design System Specification

Tài liệu đặc tả toàn bộ hệ thống Thiết kế (Design Tokens, Typography, Spacing, Component Library) của ứng dụng **InnerLamp** (iOS Native Swift UIKit).

---

## 1. Triết Lý Thiết Kế & Tổng Quan

- **Cảm hứng**: Không gian tĩnh lặng, ấm cúng và tôn nghiêm của thiền viện, ánh đèn dầu và kinh văn cổ.
- **Phong cách**: Tối giản, thanh thoát, ấm áp (Warm Minimalism), tập trung vào sự tập trung nội tâm và trải nghiệm đọc/nghe thuận tiện.
- **UI Framework**: 100% UIKit Programmatic (Auto Layout bằng code, không Storyboard).

---

## 2. Design Tokens — Màu Sắc (`ILColors`)

Tất cả màu sắc được định nghĩa trong [`ILColors.swift`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILColors.swift).

| Token | Hex / RGBA | Mục Đích Sử Dụng |
|---|---|---|
| `canvas` | `#F7F2E8` | Nền mặc định các màn danh sách, trang chủ |
| `canvasWarm` | `#FBF7EF` | Nền màn form, đọc kinh văn; gradient tới `#F1E8D8` / `#F3EADA` |
| `surface` | `#FFFDF8` | Thẻ card, hàng danh sách, ô input |
| `surfaceDark` | `#1E1B17` | Thẻ card trên nền tối |
| `surfaceDarkElevated` | `#25211C` | Thẻ tối khi active / selected |
| `darkBackground` | `#100E0B` | Nền tối cho màn thiền, player (kết hợp với đỉnh `#2A241C`) |
| `ink` | `#221E19` | Chữ chính, nút primary CTA |
| `inkSecondary` | `rgba(34,30,25, 0.70)` | Chữ phụ trên nền sáng |
| `inkTertiary` | `rgba(34,30,25, 0.50)` | Chữ thứ cấp / mô tả ngắn |
| `inkMuted` | `rgba(34,30,25, 0.42)` | Chữ mờ, placeholder, eyebrow |
| `inkDisabled` | `rgba(34,30,25, 0.30)` | Trạng thái vô hiệu hóa |
| `inkOnDark` | `#F5EEE0` | Chữ chính trên nền tối |
| `inkOnDarkSecondary` | `rgba(242,235,221, 0.60)` | Chữ phụ trên nền tối |
| `inkOnDarkTertiary` | `rgba(242,235,221, 0.42)` | Chữ thứ cấp trên nền tối |
| `inkOnDarkMuted` | `rgba(242,235,221, 0.35)` | Chữ rất mờ trên nền tối |
| `gold` | `#B8862F` | Màu nhấn chính, tiến trình, switch ON, focus ring |
| `goldBright` | `#D9963C` | Ánh đèn, chấm trạng thái, ngọn lửa đèn |
| `goldDeep` | `#8A5A18` | Chữ nhấn trên nền sáng, action header |
| `green` | `#6E8F7A` | Nhãn thiền, trạng thái thành công (chữ `#4E6C59`) |
| `rose` | `#C2857F` | Nhãn niệm Phật, cảnh báo mềm (chữ `#9A5F58`) |
| `danger` | `#A7443F` | Lỗi form, hành động xóa |
| `inkDim` | `rgba(34,30,25, 0.66)` | Mô tả dài trên nền sáng |
| `inkSubtle` | `rgba(34,30,25, 0.45)` | Nhãn/nút phụ ít nổi bật |
| `inkFaint` | `rgba(34,30,25, 0.35)` | Eyebrow/caption rất mờ trên nền sáng |
| `inkSoft` | asset `ILInkSoft` | Text tone `.ink` (xem `Tone` bên dưới) |
| `inkOnDarkVariant` | asset `ILInkOnDarkVariant` | Gốc để derive các mức `inkOnDark*` phía trên (trừ `inkOnDark`) |
| `inkOnDarkDisabled` | `rgba` (0.28 của `inkOnDarkVariant`) | Vô hiệu hóa trên nền tối |
| `goldGlow` | `rgba` (0.20 của `goldBright`) | Vầng sáng lan tỏa quanh ngọn đèn |
| `goldGlowClear` | `rgba` (alpha 0 của `goldBright`) | Điểm kết thúc trong suốt của gradient glow |
| `goldBorder` | `rgba` (0.45 của `gold`) | Viền vòng đèn |
| `border` | `rgba(34,30,25, 0.08)` | Viền thẻ tiêu chuẩn |
| `borderStrong` | `rgba(34,30,25, 0.18)` | Viền nút ghost, input active |
| `borderSoft` | `rgba(34,30,25, 0.06)` | Hairline under a sticky header strip (`--il-ink-06`) |
| `borderDark` | `rgba(242,235,221, 0.08)` | Viền thẻ trên nền tối |
| `borderDarkStrong` | `rgba(242,235,221, 0.16)` | Viền nút trên nền tối |

> **Dark appearance**: các asset màu nền (`ILCanvas`, `ILCanvasWarm*`, `ILSurface*`...) có sẵn biến thể dark-appearance khai báo trong `Assets.xcassets/Colors` — `UIColor(named:)` tự chuyển đổi theo `UITraitCollection` hiện tại, không cần code riêng.

### 2.1. Semantic Tone Helper (`ILColors.Tone`)

Dùng khi component cần đổi màu theo tone ngữ nghĩa (`gold`, `green`, `rose`, `ink`) thay vì gọi thẳng token màu — xem cách dùng trong `ILRow`, `ILChip`, `ILAvatarView`.

| Property | Mục đích |
|---|---|
| `accentColor` | Màu nhấn chính (icon, dot trạng thái) |
| `textColor` | Màu chữ nhãn/label theo tone |
| `tintBackground` | Nền mờ (tint) phía sau icon/chip |
| `avatarBackground` | Nền avatar theo tone |
| `avatarBorder` | Viền avatar theo tone |

---

## 3. Typography (`ILTypography`)

Tất cả kiểu chữ và hàm tạo AttributedString được định nghĩa trong [`ILTypography.swift`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILTypography.swift).

- **Lora** (Serif): Dùng cho tiêu đề màn (26–30px), câu kinh văn (15–21px, line-height 1.6–1.95), số đếm lớn.
- **Be Vietnam Pro** (Sans-serif): Dùng cho toàn bộ UI body, nhãn nút, input, danh mục (weight 400, 500, 600).

```swift
// Tiêu đề màn hình
titleLabel.font = ILTypography.displayMedium // Lora 26pt

// Câu kinh văn có khoảng cách dòng thoáng
scriptureLabel.attributedText = ILTypography.makeScriptureText(text: "Tâm an vạn sự an")

// Nhãn Eyebrow viết hoa (letter-spacing 0.14em)
eyebrowLabel.attributedText = ILTypography.makeEyebrow(text: "Thời khóa hôm nay")

// Nhãn nút bấm & tiêu đề danh sách
button.font = ILTypography.button // Be Vietnam Pro 13.5pt Medium
rowTitle.font = ILTypography.rowTitle // Be Vietnam Pro 14pt Medium
```

### 3.1. Toàn bộ Preset

| Preset | Font · Size · Weight | Dùng cho |
|---|---|---|
| `introDisplay` | Lora 40 Regular | Màn intro Splash/Onboarding |
| `stepTitle` | Lora 32 Regular | Tiêu đề bước Onboarding |
| `displayLarge` | Lora 30 Regular | Tiêu đề màn lớn |
| `authTitle` | Lora 29 Regular | Tiêu đề màn xác thực (Đăng ký/OTP/Đăng nhập) |
| `displayMedium` | Lora 26 Regular | Tiêu đề màn |
| `scriptureTitle` | Lora 22 Regular | Tiêu đề kinh văn |
| `scriptureBodyLarge` | Lora 20 Regular | Kinh văn cỡ lớn |
| `scriptureBody` | Lora 18 Regular | Kinh văn tiêu chuẩn |
| `scriptureBodySmall` | Lora 15 Regular | Kinh văn cỡ nhỏ |
| `taglineItalic` | Lora 14 Regular (italic tại nơi gọi) | Phụ đề dưới wordmark/tiêu đề |
| `introBody` | Be Vietnam Pro 15 Regular | Mô tả dài Onboarding |
| `otpDigit` | Be Vietnam Pro 21 Medium | Chữ số ô nhập mã OTP |
| `title1` | Be Vietnam Pro 18 SemiBold | Tiêu đề lớn trong màn |
| `title2` | Be Vietnam Pro 16 SemiBold | Tiêu đề phụ trong màn |
| `rowTitle` | Be Vietnam Pro 14 Medium | Tiêu đề hàng danh sách |
| `bodyLarge` | Be Vietnam Pro 14 Regular | Nội dung cỡ lớn |
| `button` / `headerTitle` | Be Vietnam Pro 13.5 Medium | Nhãn nút, tiêu đề header |
| `body` | Be Vietnam Pro 13.5 Regular | Nội dung tiêu chuẩn |
| `sectionTitle` | Be Vietnam Pro 13 Medium | Tiêu đề section |
| `bodySmall` / `bodySmallMedium` | Be Vietnam Pro 12.5 Regular/Medium | Nội dung cỡ nhỏ |
| `chip` | Be Vietnam Pro 12 Medium | Nhãn chip |
| `subhead` / `subheadMedium` | Be Vietnam Pro 11.5 Regular/Medium | Phụ đề |
| `logoMark` | Be Vietnam Pro 11.5 SemiBold | Wordmark viết hoa top bar |
| `label` | Be Vietnam Pro 11 Regular | Nhãn nhỏ |
| `caption` | Be Vietnam Pro 10.5 Regular | Chú thích |
| `eyebrow` | Be Vietnam Pro 10 SemiBold | Nhãn eyebrow viết hoa |
| `captionSmall` | Be Vietnam Pro 9.5 Medium | Chú thích nhỏ nhất |

---

## 4. Spacing, Bo Góc & Đổ Bóng (`ILMetrics`)

Định nghĩa trong [`ILMetrics.swift`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILMetrics.swift):

### 4.1. Spacing & Padding
- `screenPadding`: `UIEdgeInsets(top: 66, left: 20, bottom: 30, right: 20)`
- `screenHorizontal`: `20.0`
- `groupSpacing`: `20.0` (khoảng 18–24px giữa các khối)
- `rowSpacing`: `10.0` (giữa các hàng danh sách)
- `spaceSmall`: `8.0` (khoảng cách nhỏ, 6–8px)
- `spaceMedium`: `14.0` (khoảng cách trung bình, 12–16px)
- `spaceLarge`: `28.0` (khoảng cách lớn, 24–32px)

### 4.2. Bo góc (Corner Radius)
- `radiusPill`: `999.0` (Nút bấm, Chip)
- `radiusCardLarge`: `24.0` (Thẻ hero, modal sheet)
- `radiusCardSmall`: `18.0` (Hàng danh sách, thẻ phụ)
- `radiusInput`: `14.0` (Ô nhập liệu)
- `radiusIconTile`: `13.0` (Ô biểu tượng cạnh hàng)
- `radiusGlyph`: `2.0` (Bo góc biểu tượng nhỏ)

### 4.3. Chiều cao thành phần (Dimensions)
- Nút bấm (`ILButton`): `50px`
- Ô nhập (`ILField`): `48px`
- Hàng danh sách (`ILRow`): `72px`
- Ô biểu tượng (`IconTile`): `44x44px`
- Thanh điều hướng đáy (`ILBottomNavBar`): `110px` (gồm safe area)
- Ô nhập số OTP (`otpDigitBoxHeight`): `58px`
- Ảnh đèn Onboarding intro (`onboardingLampSize`): `114x160px` — `ILIcons.onboardingLamp`
- Ảnh đèn header Đăng nhập (`loginLampSize`): `40x56px` — `ILIcons.onboardingLamp`

### 4.4. Đổ bóng (`ILMetrics.Shadow`)

`Shadow` là struct dùng chung (`color`, `alpha`, `x`, `y`, `blur`, `spread`) với hàm `apply(to:)` để gán trực tiếp lên `CALayer`.

| Preset | Giá trị | Dùng cho |
|---|---|---|
| `shadowPrimaryButton` | `0 8px 24px rgba(34,30,25,.16)` | Nút primary |
| `shadowGoldButton` | `0 8px 24px rgba(184,134,47,.24)` | Nút gold |
| `shadowFloatingBar` | `0 6px 20px rgba(34,30,25,.07)` | Thanh phát nổi / card nổi |
| `shadowLampLight` | `0 8px 20px rgba(34,30,25,.28)` | Nút đèn ở thanh đáy — nền sáng |
| `shadowLampDark` | `0 0 28px rgba(217,150,60,.45)` | Nút đèn ở thanh đáy — nền tối |

```swift
ILMetrics.shadowGoldButton.apply(to: button.layer)
```

---

## 5. Danh Sách UI Components (9 Thành Phần)

Thư mục: `InnerLamp/Presentation/Common/DesignSystem/Components/`

### 5.1. [`ILButton`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILButton.swift)
Nút bấm chuẩn hỗ trợ 6 biến thể (`primary`, `gold`, `ghost`, `light`, `onDark`, `danger`), 3 trạng thái (`normal`, `loading`, `disabled`) cùng loading spinner và hiệu ứng scale khi chạm (`0.978`).

```swift
let btn = ILButton(title: "Bắt đầu thời khóa", variant: .primary)
btn.onTap = {
    print("Bắt đầu")
}
// Chuyển trạng thái loading
btn.buttonState = .loading
```

### 5.2. [`ILChip`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILChip.swift)
Thẻ chip lọc danh mục, hỗ trợ chấm trạng thái (`dot`), số lượng (`count`), chọn (`selected`) và `isDark`.

```swift
let chip = ILChip(label: "Sắp diễn ra", count: "3", hasDot: true)
chip.onTap = {
    chip.chipState = chip.chipState == .selected ? .normal : .selected
}
```

### 5.3. [`ILField`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILField.swift)
Ô nhập dữ liệu chuẩn gồm nhãn tiêu đề, bộ đếm ký tự (`counter`), ô input 48px, gợi ý (`hint`), thông báo lỗi (`error`) hoặc thành công (`success`).

```swift
let nameField = ILField(
    label: "Pháp danh hoặc tên gọi",
    placeholder: "Nhập nội dung",
    maxCount: 30
)
nameField.onTextChanged = { text in
    if text.isEmpty {
        nameField.fieldState = .error("Vui lòng không để trống")
    } else {
        nameField.fieldState = .normal
    }
}
```

### 5.4. [`ILRow`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILRow.swift)
Hàng danh sách chuẩn hiển thị bài kinh, phiên thiền, gồm ô icon 44px (glyph: `leaf`, `book`, `circle`, `dot`), tone màu (`gold`, `green`, `rose`, `ink`), tiêu đề, phụ đề và thông tin đuôi.

```swift
let row = ILRow(
    title: "Thiền hơi thở buổi sáng",
    subtitle: "12 phút · Thầy Minh Đạo",
    trailingText: "Bắt đầu",
    tone: .gold,
    glyph: .leaf
)
row.onTap = {
    // Điều hướng vào phiên thiền
}
```

### 5.5. [`ILSettingRow`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILSettingRow.swift)
Hàng cài đặt cho màn hình Settings, hỗ trợ 3 kiểu (`chevron`, `switch`, `value`), tích hợp UISwitch đổi màu theo theme.

```swift
let setting = ILSettingRow(
    title: "Chuông tỉnh thức",
    subtitle: "05:30 · 12:00 · 21:30",
    kind: .switch,
    isOn: true
)
setting.onSwitchToggled = { isOn in
    print("Chuông: \(isOn)")
}
```

### 5.6. [`ILNavBar`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILNavBar.swift)
Thanh tiêu đề dùng chung (theo `IL-NavBar.dc.html`): chip back tròn 38px bên trái, tiêu đề + phụ đề căn giữa, nút hành động pill và/hoặc nút ✕ bên phải. Hỗ trợ `isDark` cho màn hero luôn tối.

```swift
let nav = ILNavBar(title: "settings.header.title".localized, rightActionTitle: "Lưu")
nav.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
nav.onAction = { [weak self] in self?.save() }

// Modal (nút ✕ thay cho back)
let modalNav = ILNavBar(title: "Tiêu đề", showBack: false, showClose: true)
modalNav.onClose = { [weak self] in self?.dismiss(animated: true) }
```

> `ILHeaderView` (header cũ, nút `‹`/`✕` dạng chữ) đã bị xoá sau khi di trú toàn bộ màn phụ sang `ILNavBar`.

`nav.usesTransparentButtons = true` bỏ nền + viền của các nút (dùng cho màn hero ảnh, nút nằm thẳng trên ảnh; đổi `isDark` theo nền bên dưới). Mặc định `false`.

#### Dải header kính mờ — [`ILStickyHeaderBand`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILStickyHeaderBand.swift)
Dải nền sau `ILNavBar` dán cố định: lớp blur + lớp tint canvas, đi từ phẳng → kính mờ khi nội dung cuộn chui xuống dưới. Màn thêm nav bar bằng `addSubview` (band tự ghim blur/tint phía sau) rồi gọi `bind(to: scrollView)` (tiến độ = quãng cuộn qua `contentInset.top` / `ILMetrics.headerBlurFadeDistance`), hoặc `setProgress(_:)` khi tiến độ lấy từ nơi khác (hero ảnh). Độ mạnh chỉnh một chỗ ở `ILMetrics.headerBlurMaxIntensity` / `headerGlassTintAlpha`.

#### Hero ảnh co giãn — [`ILStretchyHeaderView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILStretchyHeaderView.swift)
Lớp cơ sở cho hero ảnh đầu màn cuộn (chi tiết chùa, ...): ảnh ghim trên cùng, kéo xuống thì phóng to từ mép trên, cuộn lên quá 50% chiều cao ảnh thì `onBlurProgress` báo 0…1 (đủ 1 khi ảnh qua mép trên màn hình); màn đưa giá trị này vào `ILStickyHeaderBand.setProgress(_:)` (dải header dán cố định) nên chỉ một dải cao bằng header bị mờ. Màn con kế thừa, dựng nền ở `backgroundView` (dưới ảnh), chữ/lớp phủ ở `contentView` (trên ảnh), đặt `imageHeight` (0 = không ảnh → không co giãn/mờ) và gọi `update(contentOffsetY:)` từ `scrollViewDidScroll`.

### 5.7. [`ILAvatarView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILAvatarView.swift)
Avatar đại diện dạng chữ cái viết tắt với các tone màu và tự động tính cỡ chữ theo đường kính (24–96px).

```swift
let avatar = ILAvatarView(initials: "DT", tone: .gold, size: 44)
```

### 5.8. [`ILStateView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILStateView.swift)
Màn hình/khối hiển thị trạng thái rỗng (`empty`), lỗi (`error`), mất kết nối (`offline`) hoặc hoàn thành (`done`).

```swift
let stateView = ILStateView(
    kind: .empty,
    title: "Chưa có gì ở đây",
    message: "Khi bạn bắt đầu thời khóa, mọi ghi nhận sẽ hiện ở đây."
)
```

### 5.9. [`ILBottomNavBar`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILBottomNavBar.swift)
Thanh điều hướng đáy 5 mục: **Trang chủ (`home`), Thư viện (`lib`), Đèn thiền trung tâm (`lamp`), Đạo tràng (`sangha`), Tôi (`me`)**, đi kèm quầng gradient đáy và hiệu ứng đổ bóng ngọn đèn.

```swift
let navBar = ILBottomNavBar(activeTab: .home)
navBar.onTabSelected = { tab in
    switch tab {
    case .lamp:
        // Mở chuẩn bị thiền
    default:
        // Đổi tab
    }
}
```

### 5.10. Error popups — [`Components/Alert/`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/Alert/)
The 6 shared error popups from the design handoff's "Popup lỗi" screen. Pick the kind by severity: light errors come from the top, errors needing an action come from the bottom, flow-blocking errors sit in the middle. Always go through `ILAlertPresenter` — never instantiate the views/controllers directly.

| `ILAlert` case | Type | When | Dismiss |
|---|---|---|---|
| `.toast(title:message:)` | `ILToastView` (top, light) | Light error, no action | Auto after 3.2s (countdown bar), "×", swipe up |
| `.success(title:message:)` | `ILToastView` (top, light, green tone) | Confirmation of a finished action (saved, deleted). Use this instead of an in-screen banner so layout never shifts | Auto after 3.2s (countdown bar), "×", swipe up |
| `.banner(title:message:primary:secondary:)` | `ILAlertBannerView` (top, dark rose) | Error needing a decision | A pill, swipe up |
| `.snackbar(message:action:)` | `ILSnackbarView` (bottom, dark) | One line, at most one action | Auto after 3.2s, action, swipe down |
| `.sheet(title:message:errorCode:primary:secondary:)` | `ILErrorSheetViewController` | Long context + error code | A button, tap scrim, drag down |
| `.dialog(title:message:primary:secondary:)` | `ILErrorDialogViewController` | Blocks the flow, must choose | A button only (scrim tap ignored) |
| `.fullScreen(title:subtitle:message:errorCode:primary:secondary:)` | `ILErrorFullScreenViewController` (always dark) | Severe failure, app cannot continue | A button or "×" |

Rules:
- Every button (`ILAlertAction`) dismisses the popup first, then runs its handler.
- Only one floating popup (toast/banner/snackbar) is visible at a time — a new one replaces the current one. They live on the window, so they survive navigation underneath.
- Pass copy already localized; the only built-in strings are `common.close` (accessibility) and `alert.errorCode.label`.
- Popup-specific tokens: `ILColors.Alert.*` + base assets (`alertBanner*`, `nightInk`, `scrim`, `roseOnDark`), `ILTypography.alert*`, `ILMetrics.Alert.*` + `ILMetrics.shadowToast/AlertBanner/Snackbar/AlertSheet/AlertDialog`.

```swift
ILAlertPresenter.shared.show(
    .sheet(
        title: "Thanh toán chưa hoàn tất",          // use "<key>".localized in real code
        message: "Ngân hàng từ chối giao dịch…",
        errorCode: "PAY_DECLINED_51",
        primary: ILAlertAction(title: "common.retry".localized) { [weak self] in self?.retry() },
        secondary: ILAlertAction(title: "Đổi phương thức")
    ),
    from: navigationController
)
```

### 5.11. Loading placeholders — [`ILSkeletonLoadingView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILSkeletonLoadingView.swift) & [`ILLoadMoreFooterView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILLoadMoreFooterView.swift)
From the design handoff's `loading` screen and the paginated "arts" list. Per the handoff: use the skeleton for the **first load** of library/detail content; use `ILButton.buttonState = .loading` for submit actions; use the footer for loading the next page of a list.

| Component | Looks like | API |
|---|---|---|
| `ILSkeletonLoadingView` | Pulsing lamp + "Đang thắp đèn…", then title bar, hero block, 2 tiles, 4 rows — `ilpulse` (opacity .55 ↔ .95, 1.6s), staggered | `setLoading(_:animated:)`, `caption` |
| `ILSkeletonBarView` | One pulsing rounded block (same `ilpulse` timing) — compose several into a card-shaped skeleton for a **section** that loads on its own (Home carousels / article list) | `init(color:cornerRadius:pulseDelay:)` |
| `ILLoadMoreFooterView` | 14pt gold spinner (0.9s/turn) + "Đang tải thêm…", or "Bạn đã xem hết" | `state = .hidden / .loading / .end`, `loadingText`, `endText` |

Rules:
- Overlay the skeleton on the **content area only** (pin it to the scroll view, below the header) so Back stays reachable while loading.
- Drive it from `ViewState`: `.loading` → `setLoading(true)`; `.success`/`.failure` → `setLoading(false)`. Wired in `ILLibraryViewController` and `ILArticleViewController`.
- Animations start only once the view is in a window, survive app background/foreground, and fall back to a static opacity when Reduce Motion is on.
- Tokens: `ILColors.Skeleton.*`, `ILMetrics.Skeleton.*`. Copy: `loading.caption`, `loading.more`, `loading.end`.

```swift
private lazy var skeletonView = ILSkeletonLoadingView()

private func render(state: ViewState<ILLibraryStateModel>) {
    switch state {
    case .idle: break
    case .loading: skeletonView.setLoading(true)
    case .success(let model): skeletonView.setLoading(false); updateUI(with: model)
    case .failure: skeletonView.setLoading(false)
    }
}
```

---

### 5.12. Ô nhập tìm kiếm & dải chip cuộn — [`ILSearchInputView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILSearchInputView.swift) & [`ILChipScrollView`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Components/ILChipScrollView.swift)

- `ILSearchInputView(placeholder:)`: ô tìm kiếm dạng viên thuốc có chữ nhập thật (khác `ILSearchBarView` chỉ là nút mở màn Tìm kiếm). API: `text`, `trailingText` (số kết quả, ẩn khi rỗng), `showsClearButton` (nút × tròn xóa nội dung, mặc định tắt; bật ở màn Kinh sách), `onTextChanged`, `onReturn`, `focus()` / `unfocus()`.
- `ILChipScrollView`: dải `ILChip` chọn-một cuộn ngang. API: `configure(titles:selectedIndex:)`, `onSelect(index)`.

### 5.13. Bảng màu & kích thước "Gia phả"

Cây gia phả là tranh minh họa nên dùng bảng màu cố định (không đổi theo dark mode): `ILColors.FamilyTree.*` (41 color set `ILTree*` trong `Assets.xcassets/Colors`, gồm các điểm dừng gradient huy hiệu/vòng vạch/nền tấm), preset chữ `ILTypography.tree*` (Lora thay cho Cormorant Garamond của prototype), và hình học canvas/sheet trong `ILMetrics.FamilyTree`.

## 6. Quy Tắc Dành Cho AI & Lập Trình Viên

1. **Luôn sử dụng Tokens**: Không tự ý hardcode mã màu Hex (`#...`), cỡ chữ (`UIFont.systemFont(ofSize: ...)`) hoặc tên ảnh (`UIImage(named: "...")`) trong các ViewController/Views mới. Luôn gọi qua `ILColors.*`, `ILTypography.*`, `ILMetrics.*`, `ILIcons.*`.
2. **Kế thừa Base Components**: Khi dựng màn hình mới từ 44 màn hình mẫu trong `design_handoff_innerlamp/README.md`, ưu tiên lắp ráp từ 9 thành phần trên.
3. **Hỗ trợ Dark Theme**: Khi làm việc với màn hình thiền (`session`), trình phát (`player`) hoặc chế độ tối, truyền `isDark = true` cho các component tương ứng.

---

## 7. Icons (`ILIcons` + `Assets.xcassets/Icons`)

Reusable raster icons live in `Assets.xcassets/Icons/` as `.imageset` folders and are exposed
through the [`ILIcons`](file:///Users/chjpcoj/Documents/Programming/iOS/innerlamp/InnerLamp/Presentation/Common/DesignSystem/Tokens/ILIcons.swift)
token enum — the **only** place allowed to call `UIImage(named:)`. Screens/views always use
`ILIcons.*`; do **not** redraw an icon in code (`CAShapeLayer` / `UIBezierPath`) when a matching
asset already exists.

### 7.1. Naming Convention

```
<context>_<subject>[_<state>]
```

| Segment | Meaning | Example |
|---|---|---|
| `context` | UI surface / screen the icon belongs to | `tab`, `onboarding` |
| `subject` | What the icon depicts (lowercase `snake_case`) | `lamp`, `bell` |
| `state` | Optional visual variant: `filled` (solid) vs `outline` (stroked) | `tab_lamp_filled` |

### 7.2. Existing Icons

| Token | Asset | Type | @1x size | Notes |
|---|---|---|---|---|
| `ILIcons.onboardingLamp` | `onboarding_lamp` | full-color illustration | 114×160 | Lamp + glow — Onboarding intro, Login header |
| `ILIcons.tabLampFilled` | `tab_lamp_filled` | monochrome template (black) | 28×28 | Flame + lotus pedestal, solid — bottom-nav center lamp (normal) |
| `ILIcons.tabLampOutline` | `tab_lamp_outline` | monochrome template (black) | 28×28 | Flame + lotus pedestal, stroked — bottom-nav center lamp (highlighted) |

Token naming: the asset name in `lowerCamelCase` (`tab_lamp_filled` → `tabLampFilled`).

### 7.3. Loading & Tinting

The rendering mode is baked into the token, never set at the call site:

- **Full-color** tokens (declared via `illustration(_:)`, e.g. `onboardingLamp`) use
  `.alwaysOriginal` — render as-is, do **not** tint.
- **Template** tokens (declared via `template(_:)`, e.g. `tabLampFilled` / `tabLampOutline`) use
  `.alwaysTemplate` — tint via `tintColor` with an `ILColors` constant so they follow the theme.

```swift
// Full-color illustration — render as-is
imageView.image = ILIcons.onboardingLamp

// Template icon — tintable
imageView.image = ILIcons.tabLampFilled
imageView.tintColor = ILColors.lampFlameDark
```

### 7.4. Rules

1. **Reuse first**: search `Assets.xcassets/Icons/` for a fitting icon before adding a new one.
2. **No code-drawn duplicates**: prefer the asset over a hand-drawn `CAShapeLayer`/`UIBezierPath`
   when the same icon already exists as an asset. (The four non-lamp tab icons in `ILBottomNavBar`
   are still code-drawn via `ILTabIconView` — migrate them to assets if assets are ever provided.)
3. **Always via token**: adding an icon = add the `.imageset` **and** one constant in `ILIcons`
   (`template(_:)` or `illustration(_:)`) + a row in §7.2. A missing asset `fatalError`s at
   launch in debug, so a typo is caught immediately.
4. A new icon ships `@1x/@2x/@3x` PNGs **and** a valid `Contents.json`. `.gitignore` matches
   `*.json`, so force-track the `Contents.json` with `git add -f` to make sure it is committed.
