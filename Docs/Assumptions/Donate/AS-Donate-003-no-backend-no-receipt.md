---
id: AS-Donate-003
title: No backend call; message and receipt are not delivered
title_vi: Không gọi backend; lời nhắn và biên nhận không được gửi đi
feature: Donate
level: High
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Donate/ILDonateViewModel.swift:100
source: Docs/Specs/Donate/SRS.md (FR-004, FR-006, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Tapping "Tôi đã chuyển khoản" only shows the thank-you state. The optional message is kept in memory and never sent; no receipt is created, so the prototype line "Biên nhận đã được gửi vào Thông báo" is omitted.
VI: Bấm "Tôi đã chuyển khoản" chỉ hiện màn Cảm ơn. Lời nhắn tùy chọn chỉ nằm trong bộ nhớ và không được gửi; không tạo biên nhận nên bỏ dòng "Biên nhận đã được gửi vào Thông báo" của prototype.

## Rationale / Cơ sở giả định
EN: The product owner chose "no API call" (2026-10-11); the app cannot verify a bank transfer.
VI: Chủ sản phẩm chọn "không gọi API" (11/10/2026); app không thể xác minh giao dịch ngân hàng.

## Implications if wrong / Hệ quả nếu sai
EN: Donors may expect their message to reach the team. The message field may need removal or a real endpoint.
VI: Người ủng hộ có thể kỳ vọng lời nhắn đến được đội ngũ. Có thể phải bỏ ô lời nhắn hoặc làm endpoint thật.

## Validation / Cách xác nhận
EN: Decide with the product owner whether to add an API (message + receipt) or remove the message field.
VI: Thống nhất với chủ sản phẩm: thêm API (lời nhắn + biên nhận) hay bỏ ô lời nhắn.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
