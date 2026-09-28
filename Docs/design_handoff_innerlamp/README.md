# Handoff: InnerLamp — ứng dụng tu tập (50 màn hình)

## Overview
InnerLamp là ứng dụng thiền / tụng kinh / nhật ký tu tập cho người Việt. Bundle này chứa toàn bộ bản bấm thử (clickable prototype) 45 màn hình và 9 component dùng chung, đủ để dựng phiên bản đầu tiên của app.

## About the Design Files
Các file trong `design/` là **tài liệu thiết kế viết bằng HTML** — prototype thể hiện giao diện và hành vi mong muốn, **không phải production code để copy nguyên**. Việc cần làm là **dựng lại các màn hình này trong môi trường sẵn có của codebase** (React Native, Expo, Flutter, SwiftUI, Kotlin…) theo pattern và thư viện của dự án. Nếu chưa có codebase, khuyến nghị **React Native + Expo** (app mobile, cần push notification cho chuông nhắc, cần nghe offline).

Mở `design/InnerLamp Prototype.dc.html` bằng trình duyệt để bấm thử: thanh chip dưới cùng nhảy tới bất kỳ màn nào.

## Fidelity
**High-fidelity.** Màu, typography, spacing, bo góc, trạng thái tương tác đều là giá trị cuối. Hãy dựng lại đúng pixel bằng thư viện của codebase.

## Design Tokens

### Màu
| Token | Hex | Dùng cho |
|---|---|---|
| `canvas` | `#F7F2E8` | nền mặc định các màn danh sách |
| `canvasWarm` | `#FBF7EF` | nền màn form/đọc kinh; gradient tới `#F1E8D8` hoặc `#F3EADA` |
| `surface` | `#FFFDF8` | thẻ, hàng danh sách, input |
| `surfaceDark` | `#1E1B17` | thẻ trên nền tối |
| `ink` | `#221E19` | chữ chính, nút primary |
| `inkOnDark` | `#F5EEE0` / `#F2EBDD` | chữ trên nền tối |
| `gold` | `#B8862F` | nhấn chính, progress, focus ring |
| `goldBright` | `#D9963C` | ánh đèn, chấm trạng thái, glow |
| `goldDeep` | `#8A5A18` | chữ nhấn trên nền sáng |
| `green` | `#6E8F7A` (chữ `#4E6C59`) | thiền, thành công |
| `rose` | `#C2857F` (chữ `#9A5F58`) | niệm Phật, cảnh báo mềm |
| `danger` | `#A7443F` | lỗi form, hành động xóa |
| `border` | `rgba(34,30,25,.08)` | viền thẻ |
| `borderStrong` | `rgba(34,30,25,.18)` | viền nút ghost |

Nền tối: `radial-gradient(circle at 50% 30%, #2A241C, #100E0B 74%)` cho màn thiền/player; `linear-gradient(150deg,#2A2620,#161310)` cho thẻ tối. Quầng đèn: `radial-gradient(circle, rgba(217,150,60,.22), transparent 66%)`.

Chữ trên nền tối: `rgba(242,235,221,.6)` cho phụ, `.42`/`.35` cho mờ.

### Typography
- Display/kinh văn: **Lora** (serif), weight 400, dùng cho tiêu đề màn (26–30px), câu kinh (15–21px, line-height 1.6–1.95), số lớn.
- Body/UI: **Be Vietnam Pro**, weight 400/500/600. Kích thước: 10px nhãn caps (letter-spacing .14em), 11–11.5px phụ, 12.5–14px body, 13.5px nhãn nút.
- Tiêu đề section: 500 13px. Eyebrow: 600 10px, letter-spacing .14em, uppercase, `rgba(34,30,25,.42)`.
- Cả hai font lấy từ Google Fonts với subset `vietnamese`.

### Spacing & shape
- Padding màn: `0 20px 30px` — phần chừa status bar nằm trong dải header dán (`padding-top: 56px`), không nằm ở màn.
- Khoảng cách nhóm: 18–24px; giữa các hàng trong nhóm: 10px.
- Bo góc: hàng/thẻ nhỏ 18–20px, thẻ lớn 22–26px, input 14px, icon-tile 13px, nút pill 999px.
- Chiều cao: nút 50px, input 48px, hàng danh sách 72px, icon-tile 44px, bottom nav 110px (gồm safe area).
- Shadow (hiếm): `0 8px 24px rgba(34,30,25,.16)` nút primary; `0 6px 20px rgba(34,30,25,.07)` thanh phát nổi.

## Dark / Light mode

Toàn bộ màu nền sáng đã được **rút thành CSS variable** (`--il-*`) với hai bộ giá trị. Bộ token nằm trong `<helmet>` của prototype dưới hai selector `[data-il-theme="light"]` và `[data-il-theme="dark"]`; thuộc tính `data-il-theme` đặt trên khung máy nên đổi một chỗ là cả app đổi theo.

| Token | Light | Dark | Dùng cho |
|---|---|---|---|
| `--il-canvas` | `#F7F2E8` | `#17140F` | nền màn |
| `--il-card` | `#FFFDF8` | `#211D17` | thẻ, hàng, input |
| `--il-card2` | `#FBF7EF` | `#1E1A15` | nền form/đọc kinh |
| `--il-sunk` / `-sunk2` | `#F1E8D8` / `#EFE6D5` | `#191510` / `#1B1712` | đáy gradient màn |
| `--il-paper` | `#F2EBDD` | `#1F1B15` | nền trang kinh |
| `--il-tint` → `-tint3` | `#E2D4BB` → `#CBB68F` | `#322B22` → `#4A4033` | track, cột biểu đồ |
| `--il-ink` | `#221E19` | `#F2EBDD` | chữ chính, nút primary |
| `--il-ink-NN` | `rgba(34,30,25,.NN)` | `rgba(242,235,221,.NN)` | chữ phụ, viền (39 mức alpha) |
| `--il-mid` / `-mid2` | `#4A443C` / `#6A655C` | `#B8B1A5` / `#9C958A` | icon trung tính |
| `--il-link` | `#8A5A18` | `#E8B061` | chữ nhấn, link |
| `--il-onink` | `#F7F2E8` | `#17140F` | chữ **trên** nền `--il-ink` (đảo cùng lúc) |
| `--il-med-*` | nền/chữ/vòng sáng sáng | nền/chữ/vòng sáng tối | bộ token riêng cho 4 màn immersive (Phiên thiền, Hoàn thành, Niệm Phật, Gói Sen Vàng) — gồm `--il-med-bg`, `--il-med-ink`, `--il-med-bar` (dải header), `--il-med-gold`, `--il-med-ring` |
| `--il-hover` / `--il-rowhover` | `#F3ECDE` / `#FFFFFF` | `#2A251E` | trạng thái hover |

**Không đổi theo theme** (giữ nguyên ở cả hai chế độ):
- Bảng nhấn vàng `#B8862F` `#D9963C` `#F3C673` `#E8B061`, xanh `#4E6C59`/`#6E8F7A`, hồng `#9A5F58`/`#C2857F`, đỏ lỗi `#A7443F`.
- Các màn **luôn tối** theo thiết kế: `splash`, `player`, thẻ hero tối, thiệp chia sẻ kiểu 1. (`session`, `done`, `mala`, `paywall` **đã có light mode** qua bộ `--il-med-*`.) Chúng dùng bảng `#2A241C → #100E0B` + `#F5EEE0` riêng, không đi qua token.
- Chữ đặt trên nền vàng/xanh/hồng giữ `#221E19` cứng (đã tách khỏi `--il-ink` để không bị đảo thành chữ sáng trên nền sáng).

### Lựa chọn của người dùng
Màn `lang` (Ngôn ngữ & hiển thị) có 3 lựa chọn — **Sáng / Tối / Theo máy** — nối thẳng vào state `theme` (0/1/2). Chế độ *Theo máy* đọc `prefers-color-scheme` và lắng nghe thay đổi khi đang mở app. Hàng "Chế độ tối" trong Cài đặt hiển thị lựa chọn hiện tại và bấm vào sẽ mở màn `lang`.

### Khi code (React Native)
Dùng một ThemeProvider trả về object token theo `colorScheme` (`useColorScheme()` cho chế độ *Theo máy*), lưu lựa chọn vào storage. Tên token nên giữ đúng như bảng trên để đối chiếu 1–1 với prototype. Với các màn luôn tối, hardcode bảng màu tối — **không** lấy từ theme, nếu không chúng sẽ sáng lên ở light mode.

## Launch screen (ảnh tĩnh)

Thư mục `launch/` chứa 5 ảnh launch iPhone **tối** + 5 ảnh **sáng** (`LaunchImage-Light-*`) + README riêng (cấu hình `splash.dark` trong Expo). Ảnh là **khung tĩnh** của `splash` (nền, vầng sáng, vòng đèn, ngọn lửa, wordmark, slogan) để iOS không hiện khoảng đen trước khi app mount; hiệu ứng động chỉ chạy sau đó và nối tiếp liền mạch. `backgroundColor` phải là `#100E0B` ở mọi khai báo, `resizeMode: "cover"`, và chỉ gọi `SplashScreen.hideAsync()` trong `onLayout` của màn splash động. Bảng chuyển từng hiệu ứng CSS sang Reanimated nằm trong `launch/README.md`.

Slogan chính thức: **"Tự thắp đèn tâm, tự soi lối về"** (Lora italic 15px).

## Header dùng chung: IL-NavBar

Mọi màn có header đều dùng **`IL-NavBar`** (`design/IL-NavBar.dc.html`) — thay hoàn toàn cho `IL-Header` cũ. Cấu trúc: chip back tròn 38px bên trái, tiêu đề + phụ đề căn giữa, nút hành động dạng pill và/hoặc nút ✕ bên phải.

| Prop | Kiểu | Ghi chú |
|---|---|---|
| `title` / `sub` | string | `sub` ẩn nếu rỗng |
| `right` | string | nhãn nút hành động (Lưu, Đăng, Sửa, Aa) |
| `showBack` / `showClose` | bool | modal dùng `showClose`, màn stack dùng `showBack` |
| `dark` | bool | bảng màu trên nền tối (hero ảnh) |
| `onBack` / `onClose` / `onAction` | fn | |

**Header dán cố định.** Mỗi màn bọc IL-NavBar trong một dải `position: sticky; top: 0; z-index: 40`, full-bleed (âm margin ngang bằng padding màn), `padding-top: 56px` để tránh notch, hairline `--il-ink-06` ở đáy. Padding-top của màn về 0 — **nội dung cuộn chui bên dưới lớp header**. Hai màn hero tối (Pháp thoại, Trang chùa) dùng dải kính mờ `rgba(21,18,16,.72)` + `backdrop-filter: blur(14px)`, hero được kéo lên nằm dưới header. Bốn tab gốc (Trang chủ, Thư viện, Đạo tràng, Tôi) dùng dải tiêu đề dán cùng cơ chế, không có chip back.

Khi code (React Native): một component `NavBar` + `SafeAreaView`; dùng header `position: absolute` với `paddingTop: insets.top` và cho list `contentInsetAdjustmentBehavior` / `contentContainerStyle.paddingTop` bằng chiều cao header.

## Components (10)

Mỗi component nằm ở `design/IL-*.dc.html`; logic props ở cuối file, đọc phần `renderVals()` để lấy đúng bảng màu theo state.

| Component | Props | States |
|---|---|---|
| `IL-Btn` | `label, variant(primary\|gold\|ghost\|light\|onDark\|danger), state(default\|loading\|disabled), loadingLabel, full, onTap` | hover (đổi nền), pressed (`scale(.978)`), loading (spinner 14px quay 0.9s + nhãn riêng), disabled (nền `rgba(34,30,25,.12)`, chữ `.38`) |
| `IL-Chip` | `label, state(default\|selected\|disabled), count, dot, dark, onTap` | hover, pressed (`scale(.96)`), selected (đảo nền/chữ), disabled |
| `IL-Field` | `label, value, placeholder, state(default\|focused\|error\|success\|disabled), error, hint, trailing, counter, dark` | focused (viền gold + ring `0 0 0 3px rgba(184,134,47,.16)` + caret nháy 1.05s), error (viền `#C2857F`, chữ lỗi `#A7443F`), success (`#6E8F7A`), disabled |
| `IL-Row` | `title, sub, trailing, tone(gold\|green\|rose\|ink), glyph(leaf\|book\|circle\|dot), state(default\|selected\|disabled), dark, onTap` | hover, pressed, selected (nền `rgba(184,134,47,.10)`, viền gold), disabled (opacity .5) |
| `IL-SettingRow` | `title, sub, kind(chevron\|switch\|value), trailing, on, last, dark, onTap` | switch on/off (track `#B8862F`, knob dịch 18px) |
| `IL-NavBar` | `title, sub, right, showBack, showClose, dark, onBack, onClose, onAction` | hover nút (đổi nền) |
| `IL-BottomNav` | `active(home\|lib\|lamp\|sangha\|me), onNav` | tab active, nút đèn nổi ở giữa |
| `IL-Avatar` | `initials, tone, size(24–96)` | — |
| `IL-State` | `kind(empty\|error\|offline\|done), title, body, dark` | — |

Màn **Bộ component** trong prototype (chip cuối thanh nhảy màn) hiển thị toàn bộ state — dùng nó làm checklist khi code component library.

## Cập nhật mới (bản này)
- **Bottom tab bar — icon riêng** (`IL-BottomNav`): SVG nét 1.6px, 22×22 — mái chùa (Trang chủ), kinh sách mở (Thư viện), người trong nhóm (Đạo tràng), người (Tôi). Tab active: nét `--il-ink` (tối: `#D9963C`) + fill nhẹ `--il-ink-12` (tối: `rgba(217,150,60,.22)`). Nút đèn giữa: ngọn lửa + đài sen màu `#E6A94E` (tối: `#1A1611`) trên tròn 48px.
- **Chuông mõ** (`bell`): nhịp chuông 40–160 bpm, mõ cách 5–120s; preset tụng kinh / niệm / lạy; tự đánh chuông ở mốc 10/27/108 tiếng. Âm thanh đang **tổng hợp** — cần file audio thật.
- **Ảnh chùa đẹp** (khối trên Trang chủ: 1 lớn + 2 nhỏ → màn `photos`): lọc Tất cả / Chùa / Tượng Phật / Thiền / Lễ hội, lightbox xem ảnh.
- **Chùa Việt Nam** (carousel ngang snap, thấy 1.5 thẻ): 8 chùa → `temple` (hiện dùng chung 1 template, data-bind theo chùa chọn).
- **Bài viết Phật pháp hay** (thay "bài đăng tương tác" trên Trang chủ): 5 bài biên tập → màn `article` (Lưu, Chia sẻ, Đọc tiếp). Khác với **Chia sẻ của bạn đồng tu** ở tab Đạo tràng (nội dung cộng đồng → `post`).
- **Ghi danh / Chia sẻ câu kinh**: nút hành động ghim đáy màn (sticky + hairline). Form ghi danh thêm dropdown tùy chọn "Nơi quy y" (6 lựa chọn).
- Ảnh dùng `<image-slot>` (`image-slot.js`) làm chỗ đặt ảnh — thay bằng ảnh thật khi code.

### Light mode — khối nền tối đã chuyển sang token theo theme
- Hero âm lịch (Trang chủ): `--il-hero-ov / -ink / -ink2 / -sub / -acc / -acc2`.
- Header Trang chùa: `--il-th-bg / -ink / -sub / -glow / -flame`; thanh nav trong suốt, nằm đè (height:0), gradient hero tan vào `--il-canvas` — không có đường cắt.
- Thẻ Pháp thoại (Thư viện) & Công đức (Hồ sơ): `--il-feat-bg / -bd / -glow`.
- Sáng: kicker `#74500F` (≥4.5:1 trên nền be). Giá trị đầy đủ ở rule `[data-il-theme="light"|"dark"]` đầu file prototype.

### Header chung & light mode (đợt 2)
- Mọi màn con dùng `IL-NavBar` trong wrapper sticky `padding:56px 20px 10px`, **không có line dưới header**. Màn có hero (Trang chùa, Pháp thoại, Chi tiết bài kinh) dùng bar trong suốt nằm đè (height:0) và luôn ghim trên cùng khi cuộn.
- Thông báo, Trình phát chuyển sang `IL-NavBar` (nút đóng / "Mục lục").
- Light mode thêm cho: Thông báo, Thành tựu, Thống kê, Cúng dường, Trình phát (`--il-pl-*`), Pháp thoại, Trợ giúp. Token mới: `--il-feat-track / -off / -ghost / -ghostfg`, `--il-pl-bg / -sub / -chip / -chipfg / -chipbd`.
- Cúng dường: nút "Thắp đèn" sticky đáy màn.

## Screens (50)

Nhóm theo luồng; tên trong ngoặc là key state trong prototype.

**Khởi đầu & tài khoản (9)** — `splash` màn hình chờ (xem *Launch screen* bên dưới); `onb` Onboarding 3 bước (chọn ý hướng, đặt chuông); `login` (số điện thoại); `signup` (có ô **email** để nhận biên nhận cúng dường, validate định dạng; checkbox điều khoản khóa nút CTA; nút *Gợi ý* random pháp danh; CTA ghim đáy màn, phần trên cuộn); `otp` 6 ô, 2 ô đầu đã nhập; `forgot` nhận mã qua SMS; `profile`; `edit` sửa hồ sơ; `settings`.

**Nội dung (9)** — `lib` thư viện; `search`; `empty` không kết quả; `detail` chi tiết bài kinh (hero tối + danh sách phẩm); `reader` tụng kinh (song ngữ, thanh phát dính đáy); `talk` pháp thoại; `player` trình phát toàn màn (tốc độ, hẹn giờ ngủ); `downloads` nghe không cần mạng (thanh dung lượng 3 phân đoạn); `share` chia sẻ câu kinh (3 kiểu thiệp).

**Thực hành (8)** — `home` trang chủ; `setup` chuẩn bị thiền (chọn thời lượng); `session` phiên thiền (nền tối, vòng thở); `done` hoàn thành (chọn tâm trạng); `mala` niệm Phật (bấm tăng chuỗi 108, vòng conic-gradient); `stats` tiến trình 12 tuần; `remind` chuông tỉnh thức (giờ + ngày trong tuần); `awards` 18 dấu ấn (9 mở, 9 khóa dạng nét đứt).

**Nhật ký (3)** — `journal` danh sách; `write` viết; `entry` chi tiết một ngày.

**Cộng đồng & chùa (9)** — `sangha` đạo tràng; `post` bài đăng + bình luận lồng cấp (thụt 22px); `compose` viết bài (chọn đối tượng xoay vòng, gắn thẻ); `temple` trang chùa; `events` sự kiện & khóa học (3 tab đổi danh sách); `register` ghi danh; `offer` cúng dường; `receipt` biên nhận; `cal` lịch âm — **carousel cuộn ngang theo tháng** (snap từng tháng, nút ‹ › hai bên, 6 tháng từ tháng hiện tại; ngày âm tính thật từ thuật toán lunar, tô nhẹ ngày trai, nhãn Mùng 1 / Rằm; header hiện tháng + năm can chi đang xem).

**Mới (5)** — `bell` chuông mõ; `photos` ảnh chùa đẹp; `article` bài viết Phật pháp; carousel chùa (trên `home`) → `temple`.

**Hệ thống (7)** — `notif` thông báo; `lang` ngôn ngữ & hiển thị (3 ngôn ngữ, 4 cỡ chữ đổi preview, 3 theme); `faq` trợ giúp (accordion, mở 1 mục); `paywall` gói Sen Vàng (3 gói, CTA + ghi chú đổi theo gói); `loading` skeleton (nhịp `ilpulse` 1.6s so le); `error` lỗi tải (mã lỗi + 2 nút); `offline` mất kết nối; `kit` bộ component.

## Interactions & Behavior
- **Điều hướng**: stack đơn giản — `go(screen)` đẩy màn hiện tại vào stack, nút back pop; tab bar về Trang chủ thì xóa stack.
- **Bottom nav** có ở 5 màn gốc: Trang chủ, Thư viện, Đèn (→ chuẩn bị thiền), Đạo tràng, Tôi.
- **Chuyển màn**: **crossfade mặc định** — fade out 200ms rồi fade in (`go()`, back, và mọi chip nhảy màn đều đi qua một hàm duy nhất); các step trong onboarding crossfade nhẹ hơn, 170ms. Modal vẫn trượt lên từ đáy; modal (paywall, ghi danh, viết bài, chia sẻ) trượt lên từ đáy, có nút ✕.
- **Transition trong component**: `background/border-color .16s ease`, `transform .12s ease`.
- **Animation riêng**: vòng thở phiên thiền (scale 1 → 1.12, 4s vào / 6s ra); chuỗi hạt nhấn `scale(.93)` 120ms; skeleton `ilpulse` opacity .55 ↔ .95 1.6s; spinner nút 0.9s linear.
- **Form validation**: OTP 6 số; SĐT 10 số (lỗi → state `error` của IL-Field); mật khẩu ≥ 8 ký tự; nút Tạo tài khoản disabled cho tới khi tick điều khoản.
- **Loading**: dùng màn `loading` cho lần tải đầu của thư viện/chi tiết; nút dùng `state="loading"` cho hành động gửi (ghi danh, cúng dường, đăng bài).
- **Error**: `error` khi tải nội dung thất bại (có mã lỗi + gợi ý nghe bản đã tải); `offline` khi mất mạng, vẫn cho vào phần đã tải.

## State Management
Prototype giữ toàn bộ trong một store phẳng; khi code, tách như sau:
- **Session/auth**: `user` (định danh bằng **số điện thoại**; `email` tùy chọn, dùng cho biên nhận cúng dường), `token`, `otpPending`, `plan` (free | monthly | yearly | lifetime).
- **Practice**: `beads` (0–108, 3 tràng), `sessionDuration`, `mood` sau phiên, `streak`, `weeklyMinutes[12]`, `mix` theo loại thực hành.
- **Reminders**: `bells[]` (giờ, bật/tắt), `reminderTime {h,m}`, `reminderDays[7]`.
- **Content**: `downloads[]` (trạng thái: đã tải | đang tải % | chờ Wi-Fi), `playbackSpeed`, `sleepTimer`, `fontSize`, `language`, `theme`.
- **Community**: `posts[]`, `comments[]` (có `parentId` cho trả lời lồng), `liked`, `registrations[]`.
- **Data cần API**: danh mục kinh/pháp thoại, sự kiện chùa, bài đăng + bình luận, biên nhận cúng dường, tiến trình cá nhân, thông báo.
- **Local-first**: nhật ký, chuỗi hạt, thống kê nên ghi local trước rồi đồng bộ — người dùng thường thực hành khi offline.

## Assets
Icon tab bar đã là SVG riêng (xem *Cập nhật mới*). Các "icon" còn lại vẫn là hình khối CSS (tròn, vuông bo, hình giọt `border-radius: 50% 0 50% 50%`). **Khi code nên thay bằng icon set thật** (Lucide hoặc Phosphor, nét mảnh) — giữ kích thước 13–15px trong tile 42–44px. Ảnh chùa / sự kiện hiện là gradient tối; cần ảnh thật từ phía sản phẩm.

## Files
- `design/InnerLamp Prototype.dc.html` — toàn bộ 45 màn + logic điều hướng và dữ liệu mẫu.
- `design/IL-Btn|Chip|Field|Row|SettingRow|NavBar|BottomNav|Avatar|State.dc.html` — 10 component, mỗi file gồm markup + bảng màu theo state.
- `launch/` — 10 ảnh launch tĩnh cho iOS (5 tối + 5 sáng) + hướng dẫn cấu hình Expo.
- `design/image-slot.js` — placeholder ảnh (chỉ dùng trong prototype).
- `design/support.js`, `design/ios-frame.jsx` — runtime để mở prototype trong trình duyệt; **không** port sang app.

## Gợi ý thứ tự code
1. Tokens + 9 component (dùng màn `kit` để đối chiếu state).
2. Shell điều hướng: bottom nav + stack + 5 màn gốc.
3. Luồng thực hành (setup → session → done → write) — giá trị cốt lõi, chạy offline được.
4. Nội dung (lib → detail → reader/player) + downloads.
5. Auth + paywall.
6. Cộng đồng, chùa, sự kiện.
7. Cài đặt, ngôn ngữ, trợ giúp, loading/error/offline.
