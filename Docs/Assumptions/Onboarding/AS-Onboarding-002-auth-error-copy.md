---
id: AS-Onboarding-002
title: Copy for auth messages missing from product §3.1.1
title_vi: Câu chữ cho thông báo auth chưa có trong product §3.1.1
feature: Onboarding
level: Low
status: Unvalidated
created: 2026-10-27
updated: 2026-10-27
files:
  - InnerLamp/Resources/Localization/vi.json
  - InnerLamp/Domain/Validation/ILRateLimitMessage.swift:17
source: innerlamp-be docs/product/onboarding/product.md §3.1.1, docs/product/login/product.md §3.1.1
owner: Product / BA
---

## Assumption / Giả định
EN: Where the product specs give no exact copy, the app uses copy written during the change: `auth.error.rateLimited(Seconds)`, `signup.error.registrationInProgressSeconds`, `signup.error.passwordLength`, `signup.error.displayNameTooLong`, `signup.error.fullNameInvalid`, `login.error.emailRequired`, `login.error.emailInvalid`, `otp.error.locked(Until)`, `otp.error.sendLimited(Until)`, `otp.error.resendTooSoon(Seconds)`, `signup.field.phone.hint.valid`.
VI: Ở chỗ product spec chưa có câu chính xác, app dùng câu viết trong lúc thay đổi: các key liệt kê ở phần EN.

## Rationale / Cơ sở giả định
EN: Each error in the Error → UI tables needs a visible message; the wording follows the tone of the existing keys and of the backend error meaning.
VI: Mỗi lỗi trong bảng Error → UI cần một thông báo hiển thị; câu chữ theo giọng các key có sẵn và ý nghĩa lỗi phía backend.

## Implications if wrong / Hệ quả nếu sai
EN: Strings only; replace the values in `vi.json`.
VI: Chỉ là chuỗi; thay giá trị trong `vi.json`.

## Validation / Cách xác nhận
EN: anh Đức reviews the keys above, or `ba-writer` adds them to product §3.1.1.
VI: Anh Đức duyệt các key trên, hoặc `ba-writer` bổ sung vào product §3.1.1.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
