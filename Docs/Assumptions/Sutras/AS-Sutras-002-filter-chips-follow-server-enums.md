---
id: AS-Sutras-002
title: Filter chips follow the server enums; length chips are "up to N minutes"
title_vi: Chip lọc theo đúng enum của server; chip độ dài là "đến N phút"
feature: Sutras
level: Medium
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Domain/Entities/ILSutrasEntity.swift
  - InnerLamp/Data/DataSources/Remote/SutrasPageEndpoint.swift
source: BE contract for GET /v1/sutras (purpose / tradition / daily / max_minutes); user decision 2026-10-07 "đổi chip theo đúng enum API"
owner: Product / BA
---

## Assumption / Giả định
EN: The first chip row is: All, Daily chant (`daily=true`), the 10 `purpose` values and the 3 `tradition` values (one active at a time). The second row is "any / up to 5 / up to 15 / up to 30 minutes" (`max_minutes`) because the server only supports a maximum. The prototype's 15–30 and >30 minute buckets are dropped. The 5/15/30 thresholds and the Vietnamese chip labels were chosen by the implementer.
VI: Hàng chip đầu: Tất cả, Tụng hằng ngày (`daily=true`), 10 giá trị `purpose` và 3 giá trị `tradition` (chọn một mỗi lần). Hàng thứ hai: "mọi độ dài / đến 5 / đến 15 / đến 30 phút" (`max_minutes`) vì server chỉ hỗ trợ trần tối đa. Bỏ các nhóm 15–30 và >30 phút của prototype. Các ngưỡng 5/15/30 và nhãn tiếng Việt do người implement tự chọn.

## Rationale / Cơ sở giả định
EN: Product asked to use the API enums; the API has no "minimum minutes" and filters combine with AND, so mutually exclusive chips are the closest fit to the existing single-select chip row.
VI: Product yêu cầu dùng đúng enum API; API không có "tối thiểu phút" và các bộ lọc kết hợp bằng AND, nên chip loại trừ nhau là phương án gần nhất với hàng chip chọn một hiện có.

## Implications if wrong / Hệ quả nếu sai
EN: Chip labels / thresholds need rewording; the user cannot combine a purpose with a tradition in one query.
VI: Cần đổi nhãn / ngưỡng chip; người dùng không thể kết hợp mục đích với tông phái trong một truy vấn.

## Validation / Cách xác nhận
EN: Product / BA to confirm chip set, order, labels and whether combining filters is wanted.
VI: Product / BA xác nhận bộ chip, thứ tự, nhãn và việc có cần kết hợp bộ lọc hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
