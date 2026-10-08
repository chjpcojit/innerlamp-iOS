---
id: AS-Memorial-001
title: The memorial book is local-only (Core Data) until an API contract exists
title_vi: Sổ giỗ chỉ lưu cục bộ (Core Data) cho tới khi có hợp đồng API
feature: Memorial
level: Medium
status: Invalidated
created: 2026-10-03
updated: 2026-10-07
files:
  - InnerLamp/Data/Repositories/ILMemorialRepositoryImpl.swift:11
  - InnerLamp/Data/DataSources/Local/ILMemorialLocalDataSource.swift
source: Docs/Specs/Memorial/requirements.md (Pending — backend API contract, ⚠️ Not confirmed)
owner: Product / Backend
---

## Assumption / Giả định
EN: Entries live only in the device's Core Data store. There is no sync, no per-account scope and no conflict handling; deleting the app deletes the book.
VI: Dữ liệu chỉ nằm trong Core Data trên thiết bị. Không đồng bộ, không gắn theo tài khoản, không xử lý xung đột; xóa app là mất sổ giỗ.

## Rationale / Cơ sở giả định
EN: The user decided to store locally first because no API exists yet ("hiện tại chưa có API, lưu core data thôi").
VI: Người dùng quyết định lưu cục bộ trước vì chưa có API ("hiện tại chưa có API, lưu core data thôi").

## Implications if wrong / Hệ quả nếu sai
EN: If the server is expected to be the source of truth, existing local entries need a one-time upload and a merge rule; the Core Data model may need extra fields (server id, updated-at, sync state).
VI: Nếu server là nguồn dữ liệu chính, các mục cục bộ hiện có cần được tải lên một lần và cần quy tắc gộp; model Core Data có thể cần thêm trường (server id, updated-at, trạng thái đồng bộ).

## Validation / Cách xác nhận
EN: Ask backend for the memorial-book contract (endpoints, fields, per-account scope, offline/merge rules) — `Docs/Specs/Memorial/tasks.md` Phase 4.
VI: Hỏi backend hợp đồng API sổ giỗ (endpoint, trường, phạm vi theo tài khoản, quy tắc offline/gộp) — `Docs/Specs/Memorial/tasks.md` Phase 4.

## Outcome / Kết luận
EN: Invalidated 2026-10-07. Backend shipped `/v1/memorials`; the user chose "server is the source of truth + Core Data cache" and to discard the old local-only entries (no migration). See `AS-Memorial-005` / `AS-Memorial-006`.
VI: Không còn đúng từ 2026-10-07. Backend đã có `/v1/memorials`; người dùng chọn "server là nguồn chính + cache Core Data" và bỏ dữ liệu cục bộ cũ (không migrate). Xem `AS-Memorial-005` / `AS-Memorial-006`.
