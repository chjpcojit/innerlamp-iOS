---
id: AS-LightLamp-007
title: Empty garden uses the shared empty state with placeholder copy
title_vi: Vườn đèn trống dùng trạng thái rỗng dùng chung với nội dung tạm
feature: LightLamp
level: Low
status: Validated
created: 2026-10-11
updated: 2026-10-17
files:
  - InnerLamp/Presentation/Scenes/LightLamp/ILLampGardenViewController.swift:62
source: Docs/Specs/LightLamp/requirements.md (Pending — empty-garden copy, ⚠️ Not confirmed)
owner: Design / BA
---

## Assumption / Giả định
EN: When no active lamp matches, the garden shows `ILStateView(.empty)` with "Vườn đèn còn trống" / "Thắp một ngọn đèn để nó sáng ở đây.". The prototype has no empty state.
VI: Khi không có đèn nào khớp, vườn đèn hiện `ILStateView(.empty)` với "Vườn đèn còn trống" / "Thắp một ngọn đèn để nó sáng ở đây.". Prototype không có trạng thái rỗng.

## Rationale / Cơ sở giả định
EN: A new user opens the garden with zero lamps; a blank screen is worse than a reasonable placeholder.
VI: Người dùng mới mở vườn đèn khi chưa có đèn; màn hình trống tệ hơn một nội dung tạm hợp lý.

## Implications if wrong / Hệ quả nếu sai
EN: Design may want its own illustration/copy or a call-to-action button.
VI: Design có thể muốn minh họa/nội dung riêng hoặc nút kêu gọi hành động.

## Validation / Cách xác nhận
EN: Get the empty state from Design.
VI: Xin thiết kế trạng thái rỗng từ Design.

## Outcome / Kết luận
EN: Validated by the product spec of 2026-10-16 (FR-LMP-012); the exact empty-state copy is tracked in Docs/Specs/LightLamp/requirements.md v2.0.
VI: Được product spec 2026-10-16 xác nhận (FR-LMP-012); câu chữ empty state cụ thể theo dõi ở Docs/Specs/LightLamp/requirements.md v2.0.
