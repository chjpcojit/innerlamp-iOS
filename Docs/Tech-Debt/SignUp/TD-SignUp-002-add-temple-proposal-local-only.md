---
id: TD-SignUp-002
title: Add-temple proposal at sign-up is local only
title_vi: Đề xuất thêm chùa khi đăng ký chỉ lưu cục bộ
feature: SignUp
level: High
status: Open
created: 2026-10-10
updated: 2026-10-10
files:
  - InnerLamp/Presentation/Scenes/AddTemple/ILAddTempleViewModel.swift
  - InnerLamp/Presentation/Scenes/SignUp/Views/ILOrdinationPlaceFieldView.swift
---

## Description / Mô tả
EN: The "Thêm thông tin chùa" screen (`ILAddTempleViewController`) collects name, province and address. There is no API to submit a proposal, so a valid submission only selects the temple locally as the ordination place (label "Đang chờ duyệt"); only its name is sent as `ordination_place` at sign-up. The prototype's "suggest" mode (from the temple finder) is not built.
VI: Màn "Thêm thông tin chùa" (`ILAddTempleViewController`) thu thập tên, tỉnh/thành và địa chỉ. Chưa có API gửi đề xuất nên khi hợp lệ chỉ chọn chùa đó cục bộ làm nơi xuất gia (nhãn "Đang chờ duyệt"); khi đăng ký chỉ gửi tên làm `ordination_place`. Chế độ "đề xuất" của prototype (mở từ trang tìm chùa) chưa làm.

## Why it was taken on / Lý do chấp nhận nợ
EN: No proposal-submission contract exists (same gap as TD-TempleFinder-001).
VI: Chưa có hợp đồng API gửi đề xuất chùa (cùng khoảng trống với TD-TempleFinder-001).

## Impact / Ảnh hưởng
EN: Proposed temples are never reviewed or stored server-side; address and province entered by the user are dropped.
VI: Chùa đề xuất không được duyệt hay lưu phía server; địa chỉ và tỉnh/thành người dùng nhập bị bỏ.

## Proposed fix / Hướng xử lý
EN: When the proposal API exists, send it from the sheet (before or after registration) and add the "suggest" mode if design requires it.
VI: Khi có API đề xuất, gửi từ sheet (trước hoặc sau đăng ký) và thêm chế độ "đề xuất" nếu design yêu cầu.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
