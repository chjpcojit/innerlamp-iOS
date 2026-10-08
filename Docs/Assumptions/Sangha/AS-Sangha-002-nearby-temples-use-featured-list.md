---
id: AS-Sangha-002
title: "Chùa gần bạn" is a mock list, with a fixed location label
title_vi: "Chùa gần bạn" là danh sách mẫu, nhãn vị trí cố định
feature: Sangha
level: Low
status: Unvalidated
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Domain/UseCases/Sangha/ILSanghaUseCase.swift:50
  - InnerLamp/Presentation/Scenes/Sangha/ILSanghaViewModel.swift:176
source: Docs/innerlamp-project (prototype screen `sangha`, `chNear` / `chHere`)
owner: Product / BA
---

## Assumption / Giả định
EN: The tab is UI-only (no API). The "Chùa gần bạn" list is 4 mock temples with mock distances, and the location label is the prototype's fixed "Quận 1, TP. Hồ Chí Minh". The map is a placeholder block, as in the prototype's `image-slot`.
VI: Tab hiện chỉ là UI (không gọi API). Danh sách "Chùa gần bạn" là 4 chùa mẫu với khoảng cách mẫu, nhãn vị trí là "Quận 1, TP. Hồ Chí Minh" cố định như prototype. Bản đồ là khối giữ chỗ, giống `image-slot` của prototype.

## Rationale / Cơ sở giả định
EN: The prototype sorts by distance from a fixed point; the app has no location flow or distance API yet.
VI: Prototype sắp theo khoảng cách từ 1 điểm cố định; app chưa có luồng vị trí hay API khoảng cách.

## Implications if wrong / Hệ quả nếu sai
EN: Users may see temples that are not near them; the list and label must be replaced once location is available.
VI: Người dùng có thể thấy chùa không ở gần; cần thay danh sách và nhãn khi có vị trí.

## Validation / Cách xác nhận
EN: Confirm with Product/BA whether location permission and a nearby-temples endpoint are planned.
VI: Xác nhận với Product/BA có làm quyền vị trí và API chùa gần không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
