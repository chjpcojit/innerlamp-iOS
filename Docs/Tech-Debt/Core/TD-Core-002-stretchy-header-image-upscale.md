---
id: TD-Core-002
title: Stretchy header scales an already-downsampled bitmap
title_vi: Hero co giãn phóng to bitmap đã downsample
feature: Core
level: Low
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILStretchyHeaderView.swift:109
---

## Description / Mô tả
EN: `ILRemoteImageView` downsamples to the view's size at first layout; pulling down scales that bitmap up with a transform, so it can look slightly soft at large pull distances.
VI: `ILRemoteImageView` downsample theo kích thước view ở lần layout đầu; kéo xuống phóng to bitmap đó bằng transform nên có thể hơi mờ khi kéo xa.

## Why it was taken on / Lý do chấp nhận nợ
EN: A transform avoids a layout pass per frame; the pull distance is short and transient.
VI: Dùng transform tránh layout mỗi frame; khoảng kéo ngắn và chỉ thoáng qua.

## Impact / Ảnh hưởng
EN: Cosmetic only.
VI: Chỉ thẩm mỹ.

## Proposed fix / Hướng xử lý
EN: Decode at ~1.3× the view size if softness is noticeable on device.
VI: Decode ở ~1.3× kích thước view nếu thấy mờ trên máy thật.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved)_
VI: _(điền khi Resolved)_
