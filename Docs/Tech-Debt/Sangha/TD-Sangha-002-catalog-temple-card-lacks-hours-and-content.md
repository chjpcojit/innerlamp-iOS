---
id: TD-Sangha-002
title: A practice temple picked from the directory has no opening hours / abbot and borrows mock content
title_vi: Chùa tu tập chọn từ danh bạ không có giờ mở cửa / trụ trì và dùng nội dung mẫu
feature: Sangha
level: Medium
status: Open
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Domain/UseCases/Sangha/ILSanghaUseCase.swift:104
---

## Description / Mô tả
EN: "Đổi chùa" → "Chọn chùa tu tập" saves a `{id, name, address}` snapshot of the directory temple. `loadMyTemple()` rebuilds the card from it with empty opening hours and abbot (status pill hidden, abbot "Đang cập nhật") and fills announcements / events / talks / practitioner count with the same mock content used for the sample temples. The old mock temples keep ids (`temple-*`) that do not exist in the directory, so tapping their card still opens a Temple page that 404s.
VI: "Đổi chùa" → "Chọn chùa tu tập" lưu bản chụp `{id, tên, địa chỉ}` của chùa trong danh bạ. `loadMyTemple()` dựng thẻ từ đó với giờ mở cửa và trụ trì rỗng (ẩn pill trạng thái, trụ trì "Đang cập nhật") và điền thông báo / khóa tu / pháp thoại / số Phật tử bằng cùng nội dung mẫu của các chùa mẫu. Các chùa mẫu cũ có id (`temple-*`) không tồn tại trong danh bạ nên chạm vào thẻ vẫn mở Trang chùa bị 404.

## Why it was taken on / Lý do chấp nhận nợ
EN: The whole Chùa tab is mock (TD-Sangha-001); a synchronous snapshot keeps the tab free of loading / error states for now.
VI: Cả tab Chùa đang là dữ liệu mẫu (TD-Sangha-001); bản chụp đồng bộ giúp tab chưa cần trạng thái loading / lỗi.

## Impact / Ảnh hưởng
EN: User-facing: a real temple shows other temples' mock news/events. Hours and abbot missing until the card reads `loadTempleDetail(id:)`.
VI: Ảnh hưởng người dùng: chùa thật hiện thông báo/khóa tu mẫu của chùa khác. Thiếu giờ mở cửa và trụ trì cho đến khi thẻ đọc `loadTempleDetail(id:)`.

## Proposed fix / Hướng xử lý
EN: Replace the mock temples and snapshot with `ILSanghaRepository` backed by the directory + `loadTempleDetail(id:)` (async load state in `ILSanghaViewModel`) together with the real announcements / events APIs (TD-Sangha-001).
VI: Thay chùa mẫu và bản chụp bằng `ILSanghaRepository` dựa trên danh bạ + `loadTempleDetail(id:)` (thêm trạng thái tải async ở `ILSanghaViewModel`) cùng các API thông báo / khóa tu thật (TD-Sangha-001).

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
