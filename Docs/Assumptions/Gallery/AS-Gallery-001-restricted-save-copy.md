---
id: AS-Gallery-001
title: A restricted photo library uses the save-failed toast
title_vi: Thư viện ảnh bị hạn chế dùng toast lưu thất bại
feature: Gallery
level: Low
status: Unvalidated
created: 2026-10-15
updated: 2026-10-15
files:
  - Docs/Specs/Gallery/requirements.md
  - Docs/Specs/Gallery/design.md
source: Docs/Specs/Gallery/requirements.md (criterion 30; product FR-GAL-007 gives copy for "permission refused" and "save failed" only)
owner: Product / BA
---

## Assumption / Giả định
EN: When iOS reports the add-only photo library access as `.restricted` (blocked by a device policy such as Screen Time or MDM, not refused by the user), the viewer shows the save-failed toast "Không lưu được ảnh. Vui lòng thử lại." (Couldn't save the photo. Please try again.) with no open-Settings action, instead of the permission-refused toast.
VI: Khi iOS báo quyền thêm ảnh là `.restricted` (bị chính sách thiết bị như Screen Time hoặc MDM chặn, không phải người dùng từ chối), màn xem ảnh hiển thị toast lưu thất bại "Không lưu được ảnh. Vui lòng thử lại." và không có nút mở Cài đặt, thay vì toast chưa có quyền.

## Rationale / Cơ sở giả định
EN: Product FR-GAL-007 defines only two error toasts. The permission-refused toast tells the user to open Settings, which usually cannot lift a device restriction, so offering it would mislead; `.restricted` is an iOS-only case the product spec does not name.
VI: FR-GAL-007 của product chỉ định nghĩa hai toast lỗi. Toast chưa có quyền bảo người dùng mở Cài đặt, việc thường không gỡ được hạn chế của thiết bị, nên hiển thị nó sẽ gây hiểu nhầm; `.restricted` là trường hợp chỉ có trên iOS mà product spec không nêu.

## Implications if wrong / Hệ quả nếu sai
EN: If product wants the permission-refused toast (or its own copy) for a restricted device, one branch of `ILPhotoViewerViewModel` and one test change; no other feature is affected.
VI: Nếu product muốn dùng toast chưa có quyền (hoặc câu riêng) cho thiết bị bị hạn chế, chỉ đổi một nhánh trong `ILPhotoViewerViewModel` và một test; không ảnh hưởng tính năng khác.

## Validation / Cách xác nhận
EN: Ask the product owner (anh Đức) through `ba-writer` in innerlamp-be whether FR-GAL-007 should name the restricted case.
VI: Hỏi product owner (anh Đức) qua `ba-writer` trong innerlamp-be xem FR-GAL-007 có cần nêu trường hợp bị hạn chế không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
