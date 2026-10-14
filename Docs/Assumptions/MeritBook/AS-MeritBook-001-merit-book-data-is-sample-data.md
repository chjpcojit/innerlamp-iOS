---
id: AS-MeritBook-001
title: Merit book data is in-memory sample data
title_vi: Dữ liệu Sổ công đức là dữ liệu mẫu trong bộ nhớ
feature: MeritBook
level: High
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/Repositories/ILMeritBookRepositoryImpl.swift:11
source: Docs/Specs/MeritBook/SRS.md (§3.1.3, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The shape of the offering history, letter, monthly support and financial disclosure matches the prototype's sample data (`DN_HIST`, `DN_BUILD`); there is no real API.
VI: Cấu trúc lịch sử cúng dường, thư tùy hỷ, hộ trì hằng tháng và công khai tài chính khớp dữ liệu mẫu của prototype (`DN_HIST`, `DN_BUILD`); chưa có API thật.

## Rationale / Cơ sở giả định
EN: The donation flow and its backend are not built; the user chose "mock behind a repository".
VI: Luồng cúng dường và backend chưa có; người dùng chọn "mock sau Repository".

## Implications if wrong / Hệ quả nếu sai
EN: Entities, mapper and ViewModel mapping may need rework once the real contract exists.
VI: Entity, mapper và phần map trong ViewModel có thể phải sửa khi có contract thật.

## Validation / Cách xác nhận
EN: Confirm the API contract with the backend team.
VI: Xác nhận contract API với đội backend.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
