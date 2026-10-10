---
id: TD-Core-003
title: Cormorant Garamond applied only to Splash/Login/SignUp
title_vi: Cormorant Garamond mới chỉ áp cho Splash/Đăng nhập/Đăng ký
feature: Core
level: Low
status: Resolved
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Common/DesignSystem/Tokens/ILTypography.swift
  - InnerLamp/Resources/Fonts/CormorantGaramond-Medium.ttf
---

## Description / Mô tả
EN: The new design switches display titles from Lora to Cormorant Garamond (and scripture body to Literata) app-wide. Only `splashWordmark`, `splashTagline`, `loginTitle`, `signUpTitle` use the new font; all other screens still use Lora. Literata is not bundled, so the legal sheet body uses Lora (`scriptureDescription`). Only weight 500 (+ italic) of Cormorant is bundled.
VI: Design mới đổi font tiêu đề từ Lora sang Cormorant Garamond (và thân kinh văn sang Literata) trên toàn app. Chỉ `splashWordmark`, `splashTagline`, `loginTitle`, `signUpTitle` dùng font mới; các màn khác vẫn dùng Lora. Literata chưa có trong bundle nên thân sheet pháp lý dùng Lora (`scriptureDescription`). Chỉ bundle Cormorant weight 500 (+ italic).

## Why it was taken on / Lý do chấp nhận nợ
EN: Scope of the request was Splash/Login/SignUp only; a global typography change affects many screens and needs its own review.
VI: Phạm vi yêu cầu chỉ gồm Splash/Đăng nhập/Đăng ký; đổi typography toàn app ảnh hưởng nhiều màn và cần rà soát riêng.

## Impact / Ảnh hưởng
EN: Typography is inconsistent between auth screens and the rest of the app until the global migration happens. OTP and Forgot Password still use Lora `authTitle`.
VI: Typography chưa đồng nhất giữa các màn xác thực và phần còn lại cho tới khi migrate toàn app. Màn OTP và Quên mật khẩu vẫn dùng `authTitle` Lora.

## Proposed fix / Hướng xử lý
EN: Decide the global font switch, add the needed Cormorant weights and Literata, then repoint the `ILTypography` display/scripture tokens.
VI: Chốt đổi font toàn app, thêm các weight Cormorant cần thiết và Literata, rồi trỏ lại các token display/kinh văn trong `ILTypography`.

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-10: `ILTypography` now uses Cormorant Garamond (Medium/SemiBold/Bold + Medium Italic) for display tokens and Literata (Regular/Italic) for reading tokens app-wide; the Lora files and `lora(size:)` were removed. Follow-ups are in TD-Core-004.
VI: Đã xử lý 2026-10-10: `ILTypography` dùng Cormorant Garamond (Medium/SemiBold/Bold + Medium Italic) cho token tiêu đề và Literata (Regular/Italic) cho token chữ đọc trên toàn app; đã bỏ file Lora và hàm `lora(size:)`. Việc còn lại ở TD-Core-004.
