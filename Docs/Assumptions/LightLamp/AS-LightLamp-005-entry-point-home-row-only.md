---
id: AS-LightLamp-005
title: Thắp đèn is opened only from the Home "Thắp đèn — Vu Lan" row
title_vi: Màn Thắp đèn chỉ mở từ hàng "Thắp đèn — Vu Lan" ở Home
feature: LightLamp
level: Medium
status: Invalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Home/ILHomeViewModel.swift:366
  - InnerLamp/Presentation/Scenes/Main/ILMainTabCoordinator.swift:56
source: Docs/Specs/LightLamp/requirements.md (Pending — entry points, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The center tab-bar lamp button keeps opening Chuẩn bị thiền (as the app and the feature doc do). The only entry into LightLamp is the Home suggested-session row of kind `offering`.
VI: Nút đèn giữa tab bar vẫn mở Chuẩn bị thiền (như app và tài liệu tính năng). Lối vào duy nhất là hàng gợi ý của Home loại `offering`.

## Rationale / Cơ sở giả định
EN: The prototype's `onNav('lamp')` → Thắp đèn contradicts `Mo-ta-tinh-nang.md` (→ Chuẩn bị thiền); changing the tab button would alter shipped Main behavior without confirmation.
VI: `onNav('lamp')` → Thắp đèn của prototype mâu thuẫn `Mo-ta-tinh-nang.md` (→ Chuẩn bị thiền); đổi nút tab sẽ làm thay đổi hành vi Main đã có mà chưa được xác nhận.

## Implications if wrong / Hệ quả nếu sai
EN: If Product wants the center button to open Thắp đèn, Main's `onLampTapped` and the meditation entry point need to change.
VI: Nếu Product muốn nút giữa mở Thắp đèn thì phải đổi `onLampTapped` của Main và lối vào thiền.

## Validation / Cách xác nhận
EN: Confirm the center-button destination and any other entry points (Memorial, Temple) with Product.
VI: Xác nhận đích của nút giữa và các lối vào khác (Sổ giỗ, Chùa) với Product.

## Outcome / Kết luận
EN: Partly invalidated 2026-10-11 — the product owner asked for the center tab-bar lamp button to open Thắp đèn; `ILMainTabCoordinator.onLampTapped` now does. The Home row stays an entry point. Other entry points (Memorial, Temple) remain unconfirmed. Chuẩn bị thiền is still reachable from the Home meditation row and the Meditation hub/Talk screens.
VI: Điều chỉnh một phần 2026-10-11 — chủ sản phẩm yêu cầu nút đèn giữa tab bar mở Thắp đèn; `ILMainTabCoordinator.onLampTapped` đã đổi. Hàng ở Home vẫn là lối vào. Các lối vào khác (Sổ giỗ, Chùa) chưa xác nhận. Chuẩn bị thiền vẫn mở được từ hàng thiền ở Home và màn Meditation hub/Talk.
