---
id: AS-LightLamp-002
title: The garden lists only the user's own lamps
title_vi: Vườn đèn chỉ liệt kê đèn của chính người dùng
feature: LightLamp
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/LightLamp/ILLampGardenViewModel.swift:127
source: Docs/Specs/LightLamp/requirements.md (Pending — source of community lamps, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The garden shows no other users' lamps; the prototype's 18 seeded community lamps are not reproduced. The subtitle count is the user's own active lamps.
VI: Vườn đèn không hiển thị đèn của người khác; 18 đèn cộng đồng mẫu trong prototype không được tái hiện. Số ở phụ đề là đèn đang sáng của chính người dùng.

## Rationale / Cơ sở giả định
EN: No data source exists for other users' lamps and fake lamps would mislead users into thinking others lit them.
VI: Chưa có nguồn dữ liệu đèn của người khác và đèn giả dễ khiến người dùng tưởng người khác đã thắp.

## Implications if wrong / Hệ quả nếu sai
EN: A real "community garden" feature is missing; the garden looks sparse compared with the design.
VI: Thiếu tính năng vườn đèn cộng đồng thật; vườn đèn trông thưa hơn so với thiết kế.

## Validation / Cách xác nhận
EN: Confirm with Product whether the garden is personal or community and, if community, the API/moderation rules.
VI: Xác nhận với Product vườn đèn là cá nhân hay cộng đồng; nếu cộng đồng thì cần API/quy tắc kiểm duyệt.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
