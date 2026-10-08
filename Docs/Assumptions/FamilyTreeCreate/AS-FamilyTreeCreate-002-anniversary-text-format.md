---
id: AS-FamilyTreeCreate-002
title: The death anniversary is typed as text and rejected when it cannot be read
title_vi: Ngày giỗ nhập dạng chữ và bị từ chối nếu không đọc được
feature: FamilyTreeCreate
level: Medium
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Domain/UseCases/FamilyTreeCreate/ILFamilyTreeCreateUseCase.swift:134
source: Docs/InnerLamp project/IL-GiaPha.dc.html (the "Ngày giỗ (âm lịch)" field is free text with no validation)
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype stores the anniversary as free text ("15 tháng Chạp"), but the app's member model keeps a lunar day + month (`ILFamilyLunarDate`). The build reads text such as "15 tháng Chạp", "15 tháng 12", "15/12" (day 1–30, month 1–12 as a number or a name) and shows an error for anything else, instead of silently dropping it.
VI: Prototype lưu ngày giỗ dạng chữ tự do ("15 tháng Chạp") nhưng model thành viên của app lưu ngày + tháng âm (`ILFamilyLunarDate`). Bản build đọc các dạng như "15 tháng Chạp", "15 tháng 12", "15/12" (ngày 1–30, tháng 1–12 bằng số hoặc tên) và báo lỗi với dạng khác thay vì âm thầm bỏ qua.

## Rationale / Cơ sở giả định
EN: The Sổ giỗ and the tree need real day/month values; a lunar date picker would be a design change.
VI: Sổ giỗ và cây cần giá trị ngày/tháng thật; thêm bộ chọn ngày âm là thay đổi design.

## Implications if wrong / Hệ quả nếu sai
EN: If Product wants a picker or a different format, the field and the parser change; the stored model does not.
VI: Nếu Product muốn bộ chọn hoặc định dạng khác, chỉ đổi ô nhập và bộ đọc; model lưu trữ không đổi.

## Validation / Cách xác nhận
EN: Confirm with Design whether this field becomes a lunar date picker, and whether day 30 / leap months need handling.
VI: Xác nhận với Design có đổi ô này thành bộ chọn ngày âm không, và có cần xử lý ngày 30 / tháng nhuận không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
