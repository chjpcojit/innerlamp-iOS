---
id: TD-SignUp-003
title: Add-temple duplicate check only sees the temple pages loaded so far
title_vi: Kiểm tra trùng khi thêm chùa chỉ thấy các trang chùa đã tải
feature: SignUp
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewModel.swift
  - InnerLamp/Domain/UseCases/AddTemple/ILAddTempleUseCase.swift
---

## Description / Mô tả
EN: The picker now loads temples 100 per page. `openAddTemple` still passes `ordinationPlaceOptions` as `existingPlaces`, so `ILAddTempleUseCase.validate` only compares against the pages (and the search result) currently loaded, not the full catalog.
VI: Bộ chọn giờ tải chùa theo trang 100. `openAddTemple` vẫn truyền `ordinationPlaceOptions` làm `existingPlaces`, nên `ILAddTempleUseCase.validate` chỉ so với các trang (và kết quả tìm kiếm) đang tải, không phải toàn bộ danh bạ.

## Why it was taken on / Lý do chấp nhận nợ
EN: Paging and server search were requested; checking duplicates against the whole catalog needs a server-side check that the contract does not offer.
VI: Đã được yêu cầu phân trang và tìm kiếm qua server; kiểm tra trùng trên toàn danh bạ cần server hỗ trợ mà hợp đồng chưa có.

## Impact / Ảnh hưởng
EN: A user can propose a temple that already exists on a page they have not scrolled to. The backend moderates suggestions, so the cost is a duplicate in the review queue.
VI: Người dùng có thể đề xuất một chùa đã có ở trang chưa cuộn tới. Backend duyệt đề xuất nên chi phí là một mục trùng trong hàng chờ duyệt.

## Proposed fix / Hướng xử lý
EN: Before sending the suggestion, query `GET /v1/temples/options?q=<name>` and block or warn on an exact match; or ask the backend to reject duplicates in `POST /v1/temple-suggestions`.
VI: Trước khi gửi đề xuất, gọi `GET /v1/temples/options?q=<tên>` và chặn/cảnh báo nếu trùng khớp; hoặc nhờ backend từ chối trùng ở `POST /v1/temple-suggestions`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
