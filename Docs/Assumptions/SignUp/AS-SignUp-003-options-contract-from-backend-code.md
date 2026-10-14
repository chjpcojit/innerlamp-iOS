---
id: AS-SignUp-003
title: Temple options contract was read from backend code, not captured from a server
title_vi: Hợp đồng temple options được đọc từ code backend, chưa bắt từ server thật
feature: SignUp
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/DataSources/Remote/TempleOptionsEndpoint.swift
  - InnerLamp/Data/DTOs/ILTempleOptionDTO.swift
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewModel.swift
source: Backend session [BE]-InnerLamp, 2026-10-11 (read from appService code, server not run, ⚠️ Not confirmed)
owner: Backend
---

## Assumption / Giả định
EN: `GET /v1/temples/options` returns `{items:[{id, name, province, province_code?}], page, page_size:100, total, total_pages}` in the standard envelope, is public, and sorts by heritage priority (not alphabetical). `q` searches the name only. No sample was captured from a running server, and the backend's `province_code` field was still uncommitted when reported.
VI: `GET /v1/temples/options` trả `{items:[{id, name, province, province_code?}], page, page_size:100, total, total_pages}` trong envelope chuẩn, công khai, sắp xếp theo mức ưu tiên di sản (không theo bảng chữ cái). `q` chỉ tìm theo tên. Chưa bắt mẫu từ server đang chạy, và field `province_code` của backend còn chưa commit khi được báo.

## Rationale / Cơ sở giả định
EN: The backend session read the route, handler and SQL; iOS decodes `provinceCode` as optional and ignores unknown fields, so a missing field does not break the page.
VI: Session backend đã đọc route, handler và SQL; iOS giải mã `provinceCode` là tuỳ chọn và bỏ qua field lạ nên thiếu field không làm hỏng trang.

## Implications if wrong / Hệ quả nếu sai
EN: A different envelope or key name would make every picker load fail (list stays empty, "Chưa xuất gia" still works). A different page size only changes how often "load more" fires.
VI: Envelope hoặc tên key khác sẽ làm mọi lần tải bộ chọn lỗi (danh sách trống, "Chưa xuất gia" vẫn dùng được). Kích thước trang khác chỉ đổi tần suất "tải thêm".

## Validation / Cách xác nhận
EN: Open the picker on a device against the dev backend: first page loads, scrolling appends, searching "tu quang" returns accent-insensitive matches, and submitting with a picked temple succeeds (no `400 INVALID_TEMPLE`).
VI: Mở bộ chọn trên thiết bị với backend dev: trang đầu tải được, cuộn thì nối thêm, tìm "tu quang" ra kết quả không phân biệt dấu, và gửi đăng ký với chùa đã chọn thành công (không `400 INVALID_TEMPLE`).

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
