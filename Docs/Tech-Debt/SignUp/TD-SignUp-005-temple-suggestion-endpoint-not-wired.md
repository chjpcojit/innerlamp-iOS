---
id: TD-SignUp-005
title: POST /v1/temple-suggestions endpoint exists but is not wired to AddTemple
title_vi: Endpoint POST /v1/temple-suggestions đã có nhưng chưa nối vào AddTemple
feature: SignUp
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/DataSources/Remote/TempleSuggestionEndpoint.swift
  - InnerLamp/Data/DTOs/ILTempleOptionDTO.swift
---

## Description / Mô tả
EN: `TempleSuggestionEndpoint` and its request/response DTOs are in the Data layer, but no repository, use case or screen calls them. The request needs `province_code` and `ward_code` (codes from `/v1/administrative-units/new/...`) while AddTemple only has province/ward display names. Refines TD-SignUp-002.
VI: `TempleSuggestionEndpoint` cùng DTO request/response đã có ở lớp Data nhưng chưa có repository, use case hay màn hình nào gọi. Request cần `province_code` và `ward_code` (mã từ `/v1/administrative-units/new/...`) trong khi AddTemple chỉ có tên tỉnh/phường hiển thị. Chi tiết hoá TD-SignUp-002.

## Why it was taken on / Lý do chấp nhận nợ
EN: The user asked for the Data-layer endpoints first; wiring needs a contract for administrative units and a UI decision on pending proposals.
VI: Người dùng yêu cầu làm endpoint ở lớp Data trước; nối vào cần hợp đồng đơn vị hành chính và quyết định UI cho đề xuất đang chờ duyệt.

## Impact / Ảnh hưởng
EN: A temple proposed at sign-up is still never sent to the backend (rate limit: 5 per IP per hour, `429 RATE_LIMITED`).
VI: Chùa đề xuất lúc đăng ký vẫn chưa được gửi lên backend (giới hạn 5 lượt/IP/giờ, `429 RATE_LIMITED`).

## Proposed fix / Hướng xử lý
EN: Add `ILTempleSuggestionRepository` + use case, load ward/province codes in AddTemple, call the endpoint on confirm, and map `429` to a friendly message.
VI: Thêm `ILTempleSuggestionRepository` + use case, tải mã tỉnh/phường ở AddTemple, gọi endpoint khi xác nhận và map `429` thành thông báo thân thiện.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
