---
id: AS-Donate-002
title: Transfer note follows the prototype rule
title_vi: Nội dung chuyển khoản theo quy tắc của prototype
feature: Donate
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Donate/ILDonateUseCase.swift:44
source: Docs/Specs/Donate/SRS.md (FR-005, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The transfer note is "UNGHO IL" + the first three digits of the amount, as in the prototype.
VI: Nội dung chuyển khoản là "UNGHO IL" + 3 chữ số đầu của số tiền, như prototype.

## Rationale / Cơ sở giả định
EN: No other rule was given. Known flaw: 20.000 and 200.000 both produce "UNGHO IL200".
VI: Chưa có quy tắc khác. Lỗi đã biết: 20.000 và 200.000 đều ra "UNGHO IL200".

## Implications if wrong / Hệ quả nếu sai
EN: Donations cannot be reconciled reliably by amount.
VI: Không thể đối soát khoản ủng hộ theo số tiền một cách đáng tin cậy.

## Validation / Cách xác nhận
EN: Ask the product owner / finance for the reconciliation note format.
VI: Hỏi chủ sản phẩm / kế toán về định dạng nội dung đối soát.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
