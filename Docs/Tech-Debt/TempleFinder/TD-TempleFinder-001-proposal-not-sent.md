---
id: TD-TempleFinder-001
title: Temple proposal is not sent anywhere (stub)
title_vi: Đề xuất chùa chưa được gửi đi đâu (stub)
feature: TempleFinder
level: High
status: Open
created: 2026-10-05
updated: 2026-10-05
files:
  - InnerLamp/Presentation/Scenes/TempleFinder/ILTempleFinderViewModel.swift:202
---

## Description / Mô tả
EN: A valid "Đề xuất thêm chùa" submission clears the form and shows the "Đã gửi đề xuất …" banner, but no request is made and nothing is stored. The address and phone fields are collected and then dropped.
VI: Gửi hợp lệ form "Đề xuất thêm chùa" sẽ đóng form và hiện banner "Đã gửi đề xuất …" nhưng không có request nào và không lưu gì. Ô địa chỉ và số điện thoại được thu thập rồi bỏ.

## Why it was taken on / Lý do chấp nhận nợ
EN: User asked for UI only; the backend has no proposal endpoint (only GET list / top / detail).
VI: Người dùng yêu cầu chỉ làm UI; backend chưa có endpoint đề xuất (chỉ có GET list / top / detail).

## Impact / Ảnh hưởng
EN: User-facing: the banner promises verification in 3–5 days that will never happen — misleading until wired. Proposals are lost.
VI: Ảnh hưởng người dùng: banner hứa xác minh trong 3–5 ngày nhưng sẽ không xảy ra — gây hiểu nhầm cho tới khi nối API. Đề xuất bị mất.

## Proposed fix / Hướng xử lý
EN: Agree a contract (e.g. `POST /v1/temples/proposals`), add `ILTempleProposalRepository` + endpoint via `data-builder`, send `ILTempleFinderProposal`, map errors, and show failure states. Do not ship to users before this or reword the banner.
VI: Thống nhất contract (vd. `POST /v1/temples/proposals`), thêm `ILTempleProposalRepository` + endpoint bằng `data-builder`, gửi `ILTempleFinderProposal`, map lỗi và hiển thị trạng thái thất bại. Không phát hành cho người dùng trước khi xong hoặc đổi lại nội dung banner.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
