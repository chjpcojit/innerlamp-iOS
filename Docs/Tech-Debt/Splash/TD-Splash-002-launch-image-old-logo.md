---
id: TD-Splash-002
title: Launch image still shows the old logo
title_vi: Ảnh launch vẫn là logo cũ
feature: Splash
level: Medium
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Assets.xcassets/ILLaunchImage.imageset
  - InnerLamp/Presentation/Scenes/Splash/ILSplashViewController.swift
---

## Description / Mô tả
EN: The animated splash now uses the new IL-Logo (thick 4.5px ring, two-layer SVG flame, Cormorant Garamond wordmark/tagline), but `ILLaunchImage` (light + dark) is still the old design (thin ring, drop-shaped flame, Lora). `docs/launch/*.png` in the handoff bundle is also the old render.
VI: Ảnh splash động đã dùng IL-Logo mới (vòng dày 4.5px, ngọn lửa SVG hai lớp, wordmark/slogan Cormorant Garamond), nhưng `ILLaunchImage` (sáng + tối) vẫn là bản cũ (viền mỏng, lửa hình giọt, Lora). `docs/launch/*.png` trong bundle handoff cũng là bản cũ.

## Why it was taken on / Lý do chấp nhận nợ
EN: Designer has not delivered a new launch image; the decision was to wait for the designer file instead of rendering one ourselves.
VI: Designer chưa giao ảnh launch mới; đã chốt chờ file từ designer thay vì tự render.

## Impact / Ảnh hưởng
EN: A visible jump from the launch image to the animated splash (ring weight, flame shape, font) on every cold start.
VI: Mỗi lần mở app nguội sẽ thấy khác biệt khi chuyển từ ảnh launch sang splash động (độ dày vòng, hình lửa, font).

## Proposed fix / Hướng xử lý
EN: Replace `ILLaunchImage.png` and `ILLaunchImage-Light.png` (1320x2868) with the new design export; keep `LaunchScreen.storyboard` unchanged.
VI: Thay `ILLaunchImage.png` và `ILLaunchImage-Light.png` (1320x2868) bằng bản xuất mới; giữ nguyên `LaunchScreen.storyboard`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
