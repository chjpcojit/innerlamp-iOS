---
id: TD-MeritBook-001
title: Merit book uses in-memory sample data (no API)
title_vi: Sổ công đức dùng dữ liệu mẫu trong bộ nhớ (chưa có API)
feature: MeritBook
level: High
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/Repositories/ILMeritBookRepositoryImpl.swift:19
---

## Description / Mô tả
EN: History, letter, monthly support and disclosure are hard-coded sample data; stopping monthly support is not persisted beyond the session.
VI: Lịch sử, thư, hộ trì hằng tháng và công khai tài chính là dữ liệu mẫu cố định; việc dừng hộ trì không được lưu quá phiên.

## Why it was taken on / Lý do chấp nhận nợ
EN: No donation flow or backend contract exists; UI could still be built and verified.
VI: Chưa có luồng cúng dường hay contract backend; vẫn dựng và kiểm UI được.

## Impact / Ảnh hưởng
EN: Users would see fake offerings in a production build.
VI: Người dùng sẽ thấy các lần cúng dường giả nếu phát hành.

## Proposed fix / Hướng xử lý
EN: Define the contract, add DTO + Mapper + Endpoint, replace the repository implementation (data-builder). Gate the screen until then.
VI: Chốt contract, thêm DTO + Mapper + Endpoint, thay implementation repository (data-builder). Ẩn màn cho tới lúc đó.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
