---
id: AS-Memorial-006
title: The server is the source of truth; offline the book is read-only from the cache, and old local entries are discarded
title_vi: Server là nguồn chính; offline chỉ đọc từ cache, dữ liệu cục bộ cũ bị bỏ
feature: Memorial
level: Medium
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Data/Repositories/ILMemorialRepositoryImpl.swift
source: Backend openapi.yaml `/v1/memorials` (docs/specs/api/openapi.yaml in the backend repo)
owner: Product / Backend
---

## Assumption / Giả định
EN: Reads go to `GET /v1/memorials` and replace the whole Core Data cache. The cache is served only on an offline/timeout failure (never on 401), and only rows with a numeric id. Create/edit/delete need the network and fail with `offline` otherwise (no queue). Entries that existed only in Core Data before this integration are discarded on the first successful load (user decision 2026-10-07: "xoá và làm lại từ đầu"). The server returns at most 100 entries; the 101st create fails with `limitReached`. Photos are not synced (`photo_url` is always null).
VI: Mỗi lần đọc gọi `GET /v1/memorials` và thay toàn bộ cache Core Data. Cache chỉ được dùng khi lỗi offline/timeout (không dùng khi 401), và chỉ với dòng có id số. Thêm/sửa/xóa cần mạng, không có mạng thì báo `offline` (không xếp hàng). Mục chỉ có trong Core Data từ trước khi tích hợp bị bỏ ở lần tải thành công đầu tiên (quyết định của người dùng 2026-10-07: "xoá và làm lại từ đầu"). Server trả tối đa 100 mục; tạo mục thứ 101 báo `limitReached`. Ảnh chưa đồng bộ (`photo_url` luôn null).

## Rationale / Cơ sở giả định
EN: The API has no updated-since or conflict support, so a merge/offline-write model would be guesswork; user chose "server + cache".
VI: API không có updated-since hay xử lý xung đột nên mô hình merge/ghi offline chỉ là đoán; người dùng chọn "server + cache".

## Implications if wrong / Hệ quả nếu sai
EN: Users who add entries on a train without signal get an error instead of a saved entry; any build already in testers' hands loses its local-only entries.
VI: Người dùng thêm mục khi không có sóng sẽ gặp lỗi thay vì lưu được; bản đã phát cho tester sẽ mất các mục chỉ lưu cục bộ.

## Validation / Cách xác nhận
EN: Confirm with Product that offline writes are not required; confirm no released build holds real local entries.
VI: Xác nhận với Product là không cần ghi offline; xác nhận chưa có bản phát hành nào chứa dữ liệu cục bộ thật.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
