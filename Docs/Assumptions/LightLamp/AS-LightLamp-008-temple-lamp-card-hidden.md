---
id: AS-LightLamp-008
title: "Thỉnh đèn tại chùa" card is not shown on the completion state
title_vi: Thẻ "Thỉnh đèn tại chùa" không hiện ở trạng thái hoàn tất
feature: LightLamp
level: Low
status: Validated
created: 2026-10-11
updated: 2026-10-17
files:
  - InnerLamp/Presentation/Scenes/LightLamp/ILLightLampViewController.swift:118
source: Docs/Specs/LightLamp/requirements.md (Pending — temple-lamp card, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The completion state shows the dedication card and the two actions only. The prototype's "Thỉnh đèn tại chùa" card is omitted because it leads to the donation flow, which is out of scope.
VI: Trạng thái hoàn tất chỉ có thẻ hồi hướng và hai nút. Thẻ "Thỉnh đèn tại chùa" của prototype bị bỏ vì dẫn tới luồng cúng dường, ngoài phạm vi.

## Rationale / Cơ sở giả định
EN: A tappable card that does nothing is a broken affordance; the donation flow (`Docs/Specs/Offering/`) is separate.
VI: Thẻ chạm được mà không làm gì là lỗi trải nghiệm; luồng cúng dường (`Docs/Specs/Offering/`) là feature riêng.

## Implications if wrong / Hệ quả nếu sai
EN: When the donation flow lands the card has to be added and routed.
VI: Khi có luồng cúng dường phải thêm thẻ và điều hướng.

## Validation / Cách xác nhận
EN: Revisit when `Offering` is implemented.
VI: Xem lại khi `Offering` được triển khai.

## Outcome / Kết luận
EN: Validated by product decision of 2026-10-16: "Thỉnh đèn tại chùa" stays hidden on every platform (scope: light a lamp and the garden only).
VI: Được quyết định product 2026-10-16 xác nhận: "Thỉnh đèn tại chùa" tiếp tục ẩn trên mọi nền tảng (phạm vi chỉ thắp đèn và vườn đèn).
