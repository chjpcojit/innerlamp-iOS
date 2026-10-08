---
id: TD-TempleFinder-002
title: Search covers only name + address; rows show the address only
title_vi: Tìm kiếm chỉ theo tên + địa chỉ; hàng chùa chỉ hiện địa chỉ
feature: TempleFinder
level: Low
status: Open
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Presentation/Scenes/TempleFinder/ILTempleFinderViewModel.swift:281
---

## Description / Mô tả
EN: The prototype searches name, aliases, district and province and shows "district, province · rank" per row. `GET /v1/temples` rows carry only name, region and a full address (aliases are in the detail response), so search matches name + address and the row subtitle is the address. All ~179 temples are loaded up front and filtered on the client.
VI: Prototype tìm theo tên, tên khác, quận/huyện, tỉnh và hiện "quận, tỉnh · hạng" ở mỗi hàng. Hàng của `GET /v1/temples` chỉ có tên, miền và địa chỉ đầy đủ (tên khác nằm ở response chi tiết) nên tìm theo tên + địa chỉ và dòng phụ là địa chỉ. Toàn bộ ~179 chùa được tải trước rồi lọc ở client.

## Why it was taken on / Lý do chấp nhận nợ
EN: Contract limits; avoids per-temple detail calls.
VI: Giới hạn contract; tránh gọi chi tiết từng chùa.

## Impact / Ảnh hưởng
EN: Searching a folk name ("chùa Bà Đá") finds nothing. Loading all pages scales poorly if the directory grows a lot (first open is network-bound; later opens use the Core Data cache).
VI: Tìm theo tên dân gian ("chùa Bà Đá") không ra. Tải hết các trang sẽ kém khi danh bạ lớn hơn nhiều (lần mở đầu phụ thuộc mạng; các lần sau dùng cache Core Data).

## Proposed fix / Hướng xử lý
EN: Ask the backend for a search endpoint (`/v1/temples?q=`) and aliases / heritage rank in list rows; then search server-side and page the list.
VI: Đề nghị backend thêm endpoint tìm kiếm (`/v1/temples?q=`) và trả tên khác / hạng di tích trong list; sau đó tìm phía server và phân trang danh sách.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
