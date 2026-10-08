---
id: AS-Memorial-003
title: A lunar entry only counts in the regular month, never in a leap month
title_vi: Ngày giỗ âm lịch chỉ tính vào tháng thường, không tính vào tháng nhuận
feature: Memorial
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/Memorial/ILMemorialUseCase.swift:96
source: Docs/Specs/Memorial/requirements.md (Pending — leap months, ⚠️ Not confirmed)
owner: Product
---

## Assumption / Giả định
EN: For a lunar entry the next giỗ is computed in the regular lunar month only (`lunarToSolar(..., isLeap: false)`); the leap month is skipped, so there is one giỗ per lunar year.
VI: Với ngày giỗ âm lịch, kỳ giỗ tới chỉ được tính trong tháng âm thường (`lunarToSolar(..., isLeap: false)`); tháng nhuận bị bỏ qua, nên mỗi năm âm chỉ có một kỳ giỗ.

## Rationale / Cơ sở giả định
EN: Matches how most families keep giỗ (once a year on the regular month) and the user's chosen default. The same "regular month only" rule is used for recurring Buddhist events unless a template opts in.
VI: Khớp với cách đa số gia đình cúng giỗ (mỗi năm một lần vào tháng thường) và mặc định người dùng đã chọn. Cùng quy tắc "chỉ tháng thường" được dùng cho sự kiện Phật giáo định kỳ trừ khi mẫu cho phép.

## Implications if wrong / Hệ quả nếu sai
EN: A family that observes the giỗ in the leap month as well, or only when the person died in a leap month, gets the wrong date. A death recorded in a leap month cannot be expressed at all (no leap flag on the entry).
VI: Gia đình cúng giỗ cả ở tháng nhuận, hoặc người mất vào tháng nhuận, sẽ thấy sai ngày. Trường hợp mất vào tháng nhuận không thể biểu diễn (mục chưa có cờ nhuận).

## Validation / Cách xác nhận
EN: Ask Product / a domain expert; if leap months matter, add an `isLeapMonth` field to the entry and the form.
VI: Hỏi Product / chuyên gia nghiệp vụ; nếu tháng nhuận quan trọng, thêm trường `isLeapMonth` cho mục và form.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
