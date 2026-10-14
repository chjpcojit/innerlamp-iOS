---
id: AS-Donate-001
title: Receiving account and QR payload are placeholders
title_vi: Tài khoản nhận tiền và nội dung QR chỉ là giá trị tạm
feature: Donate
level: Critical
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/Repositories/ILMockDonationAccountRepository.swift:14
source: Docs/Specs/Donate/SRS.md (FR-005, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Recipient "Công ty InnerLamp", bank "Vietcombank" and the QR payload are placeholders taken from the prototype. The QR payload is intentionally not a bank (VietQR/EMVCo) payload.
VI: Người nhận "Công ty InnerLamp", ngân hàng "Vietcombank" và nội dung QR là giá trị tạm lấy từ prototype. Nội dung QR cố ý không phải payload ngân hàng (VietQR/EMVCo).

## Rationale / Cơ sở giả định
EN: The product owner has no real account details yet (2026-10-11) and chose a mock behind a repository protocol.
VI: Chủ sản phẩm chưa có thông tin tài khoản thật (11/10/2026) và chọn mock phía sau repository protocol.

## Implications if wrong / Hệ quả nếu sai
EN: Shipping as-is would show a QR that cannot be scanned into any banking app, so no donation can be made. Blocks release.
VI: Phát hành nguyên trạng thì mã QR không quét được vào app ngân hàng nên không ai ủng hộ được. Chặn release.

## Validation / Cách xác nhận
EN: Get bank, account number, holder name and VietQR payload (or an API) from the product owner; replace the mock repository.
VI: Lấy ngân hàng, số tài khoản, tên chủ tài khoản và payload VietQR (hoặc API) từ chủ sản phẩm; thay repository mock.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
