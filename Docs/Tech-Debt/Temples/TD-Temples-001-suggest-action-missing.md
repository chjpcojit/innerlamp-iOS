---
id: TD-Temples-001
title: "Đề xuất" nav-bar action of the all-temples screen is not built
title_vi: Chưa làm nút "Đề xuất" trên màn Tất cả chùa
feature: Temples
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/Temples/ILTemplesViewController.swift
---

## Description / Mô tả
EN: The prototype screen `temples` has a right-side "Đề xuất" action that opens the add-temple form. It was left out.
VI: Prototype có nút "Đề xuất" bên phải nav bar mở form thêm chùa. Chưa làm.

## Why it was taken on / Lý do chấp nhận nợ
EN: `AddTemple` is coupled to the sign-up flow (ordination places, proposal handed back to SignUp) and no API sends a standalone proposal, so the button would appear to succeed while sending nothing.
VI: `AddTemple` gắn với luồng đăng ký (nơi xuất gia, trả đề xuất về SignUp) và chưa có API gửi đề xuất độc lập, nên nút sẽ báo thành công giả.

## Impact / Ảnh hưởng
EN: Users cannot suggest a missing temple from this screen (they still can from SignUp / TempleFinder).
VI: Người dùng không đề xuất chùa thiếu được từ màn này (vẫn đề xuất được ở SignUp / TempleFinder).

## Proposed fix / Hướng xử lý
EN: Add the action once a proposal API exists; reuse `ILAddTempleCoordinator` or the TempleFinder form.
VI: Thêm nút khi có API gửi đề xuất; dùng lại `ILAddTempleCoordinator` hoặc form của TempleFinder.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
