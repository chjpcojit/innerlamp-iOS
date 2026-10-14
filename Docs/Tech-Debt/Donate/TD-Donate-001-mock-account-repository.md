---
id: TD-Donate-001
title: Receiving account served by a mock repository
title_vi: Tài khoản nhận tiền do repository mock cung cấp
feature: Donate
level: Critical
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/Repositories/ILMockDonationAccountRepository.swift:14
  - InnerLamp/App/DIContainer.swift
---

## Description / Mô tả
EN: `DIContainer.makeDonationAccountRepository()` returns `ILMockDonationAccountRepository` with placeholder recipient, bank and a non-bank QR payload.
VI: `DIContainer.makeDonationAccountRepository()` trả về `ILMockDonationAccountRepository` với người nhận, ngân hàng và payload QR giả.

## Why it was taken on / Lý do chấp nhận nợ
EN: Real account details were not available when the screen was built.
VI: Chưa có thông tin tài khoản thật khi dựng màn hình.

## Impact / Ảnh hưởng
EN: Donations cannot be completed in production. Blocks release.
VI: Không thể ủng hộ thật trên production. Chặn release.

## Proposed fix / Hướng xử lý
EN: Provide real account data (constants, remote config or API) and swap the repository in `DIContainer`; see AS-Donate-001.
VI: Cung cấp dữ liệu tài khoản thật (hằng số, remote config hoặc API) và thay repository trong `DIContainer`; xem AS-Donate-001.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
