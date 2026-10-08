---
id: AS-Core-002
title: Sticky headers share one fade distance (40pt)
title_vi: Mọi header dán cố định dùng chung một quãng cuộn mờ (40pt)
feature: Core
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILStickyHeaderBand.swift
  - InnerLamp/Presentation/Common/DesignSystem/Tokens/ILMetrics.swift:130
source: user request — one-place header blur
owner: Design
---

## Assumption / Giả định
EN: Article, SutraDetail and LunarDayDetail previously blurred over 120pt of scroll; Home and Profile over 40pt. After moving to `ILStickyHeaderBand` all use `ILMetrics.headerBlurFadeDistance` (40pt), so those three headers now go glass faster.
VI: Article, SutraDetail, LunarDayDetail trước đây mờ dần trong 120pt cuộn; Home, Profile là 40pt. Sau khi chuyển sang `ILStickyHeaderBand`, tất cả dùng `ILMetrics.headerBlurFadeDistance` (40pt) nên 3 màn kia mờ nhanh hơn.

## Rationale / Cơ sở giả định
EN: The goal is one tunable value for every header; keeping per-screen distances would defeat it.
VI: Mục tiêu là một giá trị chỉnh chung cho mọi header; giữ riêng từng màn sẽ mất ý nghĩa.

## Implications if wrong / Hệ quả nếu sai
EN: Slightly different feel on three screens; fix by passing `fadeDistance:` to `bind(to:)` or changing the token.
VI: Cảm giác hơi khác ở 3 màn; sửa bằng truyền `fadeDistance:` vào `bind(to:)` hoặc đổi token.

## Validation / Cách xác nhận
EN: User checks the three screens on device.
VI: Người dùng kiểm tra 3 màn trên thiết bị.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated)_
VI: _(điền khi Validated/Invalidated)_
