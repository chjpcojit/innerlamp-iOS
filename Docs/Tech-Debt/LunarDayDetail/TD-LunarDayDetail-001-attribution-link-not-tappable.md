---
id: TD-LunarDayDetail-001
title: Image attribution is plain text, not a link
title_vi: Ghi công ảnh chỉ là văn bản, không bấm được
feature: LunarDayDetail
level: Medium
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/LunarDayDetail/Views/ILLunarDayDetailHeroView.swift
---

## Description / Mô tả
EN: The hero shows "Ảnh: <author> · <license>" as a plain caption. The API also returns license_url and source_url, which are not used.
VI: Hero hiển thị "Ảnh: <tác giả> · <giấy phép>" dạng chữ thường. API còn trả license_url và source_url nhưng chưa dùng.

## Why it was taken on / Lý do chấp nhận nợ
EN: Opening an external URL needs a coordinator-owned navigation event and a product decision on where the link goes; not required to ship the image.
VI: Mở URL ngoài cần sự kiện điều hướng do Coordinator quản lý và quyết định của product về đích của link; chưa bắt buộc để ra ảnh.

## Impact / Ảnh hưởng
EN: Most images are CC BY / CC BY-SA, which may require a link to the license/source; shipping without it may be non-compliant.
VI: Phần lớn ảnh là CC BY / CC BY-SA, có thể yêu cầu link tới giấy phép/nguồn; phát hành thiếu link có thể chưa đạt.

## Proposed fix / Hướng xử lý
EN: Make the caption tappable: a nav event .openURL(URL) handled by ILLunarDayDetailCoordinator (SFSafariViewController), using source_url (fallback license_url). Confirm the legal requirement first.
VI: Cho caption bấm được: nav event .openURL(URL) do ILLunarDayDetailCoordinator xử lý (SFSafariViewController), dùng source_url (dự phòng license_url). Xác nhận yêu cầu pháp lý trước.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
