# Launch screen (ảnh tĩnh) — InnerLamp

Mục đích: xoá khoảng đen xuất hiện trước khi splash động mount.

## Hai bộ ảnh: Tối & Sáng
- `LaunchImage-*.png` — **tối** (mặc định): nền `#2A241C → #100E0B`, fill `#100E0B`.
- `LaunchImage-Light-*.png` — **sáng**: nền radial `#FFFCF4 → #F0E6D4` (tâm 50% 42%), vòng đèn `rgba(138,90,24,.38)`, wordmark `#221E19`, slogan `rgba(34,30,25,.72)`, fill `#F0E6D4`. Khớp token `--il-spl-*` light của splash động.

iOS tự chọn ảnh theo chế độ máy. App đặt theme riêng (Sáng/Tối) chỉ áp dụng **sau** launch — launch luôn theo hệ thống.

## Nội dung ảnh
Đúng trạng thái tĩnh (steady frame) của màn hình chờ: nền radial `#2A241C → #100E0B`, vầng sáng cam, vòng đèn 96px, ngọn lửa, wordmark "InnerLamp", slogan "Tự thắp đèn tâm, tự soi lối về".

Không có ripple / ember / dots — hiệu ứng động chỉ chạy sau khi app mount, nối tiếp liền mạch từ ảnh này nên mắt không thấy điểm cắt.

## File
| File | Thiết bị |
|---|---|
| LaunchImage[-Light]-1320x2868.png | iPhone 16 Pro Max |
| LaunchImage[-Light]-1206x2622.png | iPhone 16 Pro |
| LaunchImage[-Light]-1179x2556.png | iPhone 14/15/16 Pro, 15/16 |
| LaunchImage[-Light]-1284x2778.png | iPhone 12–14 Pro Max |
| LaunchImage[-Light]-1170x2532.png | iPhone 12–14, 13/14 |

Expo chỉ cần **một** ảnh (dùng 1320×2868 làm nguồn, `resizeMode: cover`); các size còn lại dành cho bản native thuần nếu dùng Asset Catalog.

## Expo (app.json)
```json
{
  "expo": {
    "backgroundColor": "#100E0B",
    "splash": {
      "image": "./assets/launch/LaunchImage-Light-1320x2868.png",
      "resizeMode": "cover",
      "backgroundColor": "#F0E6D4",
      "dark": {
        "image": "./assets/launch/LaunchImage-1320x2868.png",
        "backgroundColor": "#100E0B"
      }
    },
    "ios": { "userInterfaceStyle": "automatic" },
    "android": { "userInterfaceStyle": "automatic" }
  }
}
```
- `resizeMode: "cover"` — **không** dùng `contain`: `contain` để lộ viền nền và tạo cảm giác nhảy hình.
- `backgroundColor`: `#F0E6D4` cho sáng, `#100E0B` cho tối (`splash.dark`) — màu lấp trước khi ảnh vẽ.
- `userInterfaceStyle: "automatic"` để iOS/Android chọn đúng bộ ảnh; status bar: chữ tối ở sáng, chữ sáng ở tối.
- Với Asset Catalog native: thêm biến thể *Appearance → Any, Dark* trong LaunchImage imageset (Any = Light, Dark = bản tối).

## Nối liền mạch sang splash động
```js
import * as SplashScreen from 'expo-splash-screen';

SplashScreen.preventAutoHideAsync();              // gọi ở top-level module
SplashScreen.setOptions({ duration: 0, fade: false });

// trong App: chỉ ẩn SAU khi Splash động đã vẽ xong frame đầu
<SplashAnimated onLayout={() => SplashScreen.hideAsync()} />
```
Quy tắc: gọi `hideAsync()` trong `onLayout` của màn splash động, không gọi trong `useEffect` sớm — nếu không sẽ thấy lại một nhịp đen giữa hai lớp.

## Dựng lại hiệu ứng trên iOS
Hiệu ứng CSS ở bản prototype (`ilripple`, `ilignite`, `ilember`, `ilword`, `ilray`) không mang sang React Native được. Cần dựng lại:

| Hiệu ứng | Cách làm trong RN |
|---|---|
| ripple (3 vòng lan) | `react-native-reanimated`: `withRepeat(withTiming(...))` trên `scale` + `opacity`, delay 0 / 1.1s / 2.2s |
| ignite (lửa bùng) | `withSequence(withTiming(1.22, 420), withTiming(0.92, 200), withTiming(1, 180))` |
| pulse (nhịp thở) | `withRepeat(withTiming(opacity .55↔.95, 1300), -1, true)` |
| ember (tàn lửa bay) | 3 `View` nhỏ, `translateY: 0 → -190`, `opacity` fade, loop lệch pha |
| glow / vầng sáng | `react-native-svg` `RadialGradient` hoặc PNG có alpha — `shadowColor` của RN không đủ mềm |
| word blur→sharp | RN không có `filter: blur`: thay bằng fade + animate `letterSpacing` (.34em → 0); cần blur thật thì dùng `@react-native-masked-view` + `expo-blur` |
| ray (tia quét) | 2 `View` mảnh, `transform: [{rotate}, {scaleY}]`, `transformOrigin` bottom |

Tất cả chạy qua Reanimated (UI thread) để giữ 60fps trên máy yếu; **không** dùng `Animated` của RN core cho ripple/ember vì chạy trên JS thread sẽ giật lúc app đang khởi động.
