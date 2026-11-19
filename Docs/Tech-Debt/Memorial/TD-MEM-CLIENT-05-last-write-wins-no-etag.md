---
id: TD-MEM-CLIENT-05
title: Concurrent edits are last-write-wins; the contract has no ETag
title_vi: Sửa đồng thời theo last-write-wins; contract không có ETag
feature: Memorial
level: Medium
status: Open
created: 2026-11-16
updated: 2026-11-16
files:
  - InnerLamp/Data/Repositories/ILMemorialRepositoryImpl.swift
---

## Description / Mô tả
EN: `PUT /v1/memorials/{id}` replaces the whole document with no version or `If-Match`. The second device to save wins and the first device's edit is lost silently.
VI: `PUT /v1/memorials/{id}` thay toàn bộ document, không có version hay `If-Match`. Máy lưu sau thắng, sửa của máy trước mất im lặng.

## Why it was taken on / Lý do chấp nhận nợ
EN: The v1 contract has no conflict response and the product has not asked for merge; adding ETag would change the backend contract (technical decision D7/D10).
VI: Contract v1 không có phản hồi xung đột và product chưa yêu cầu merge; thêm ETag sẽ đổi contract BE (quyết định D7/D10).

## Impact / Ảnh hưởng
EN: Two people editing the same entry at the same time can silently overwrite each other; there is no warning.
VI: Hai người sửa cùng một mục cùng lúc có thể ghi đè nhau mà không có cảnh báo.

## Proposed fix / Hướng xử lý
EN: Add `ETag`/`If-Match` and a 409 conflict path in the backend, then surface a reload-or-overwrite choice in the form.
VI: Thêm `ETag`/`If-Match` và nhánh 409 ở BE, rồi cho form chọn tải lại hoặc ghi đè.

## Owner and repayment condition / Chủ nợ và điều kiện trả
EN: Owner ⚔ Đạo Sư ⚔. Condition: A real multi-device need, or an ETag in the contract.
VI: Chủ nợ ⚔ Đạo Sư ⚔. Điều kiện: Có nhu cầu thật nhiều thiết bị, hoặc contract có ETag.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
