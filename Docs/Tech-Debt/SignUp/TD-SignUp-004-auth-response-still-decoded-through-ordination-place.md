---
id: TD-SignUp-004
title: Login / verify-otp response is still decoded through ordination_place
title_vi: Phản hồi đăng nhập / verify-otp vẫn giải mã qua ordination_place
feature: SignUp
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/DTOs/ILLoginDTO.swift:65
  - InnerLamp/Data/DTOs/ILOtpDTO.swift:41
  - InnerLamp/Data/DTOs/Mappers/ILLoginMapper.swift:32
  - InnerLamp/Data/DTOs/Mappers/ILOtpMapper.swift:23
---

## Description / Mô tả
EN: Confirmed by the backend (2026-10-11): `verify-otp` and `login` return `user.ordination_temple_id` (key absent when no temple is chosen) and **never** `ordination_place` or a temple name. `ILOtpUserDTO` / `ILLoginUserDTO` still declare an optional `ordinationPlace`, which is always `nil`, so the cached user's `ordinationPlace` is always empty. The name is only available from `GET /v1/users/me` (`ordination_temple: {id, name}`) or `GET /v1/temples/{id}`.
VI: Backend xác nhận (2026-10-11): `verify-otp` và `login` trả `user.ordination_temple_id` (không có key khi chưa chọn chùa) và **không bao giờ** trả `ordination_place` hay tên chùa. `ILOtpUserDTO` / `ILLoginUserDTO` vẫn khai báo `ordinationPlace` tuỳ chọn nên luôn `nil`, `ordinationPlace` của user trong cache luôn rỗng. Tên chùa chỉ có ở `GET /v1/users/me` (`ordination_temple: {id, name}`) hoặc `GET /v1/temples/{id}`.

## Why it was taken on / Lý do chấp nhận nợ
EN: Out of scope of the picker task (surgical changes); the user entity has no temple id field yet and Profile/EditProfile consume `ordinationPlace` as a name.
VI: Ngoài phạm vi task bộ chọn (thay đổi tối thiểu); entity user chưa có trường id chùa và Profile/EditProfile đang dùng `ordinationPlace` như một tên.

## Impact / Ảnh hưởng
EN: Profile and Edit Profile may show an empty ordination place for users who picked a temple at sign-up.
VI: Profile và Sửa hồ sơ có thể hiện nơi xuất gia rỗng với người dùng đã chọn chùa lúc đăng ký.

## Proposed fix / Hướng xử lý
EN: Add `ordination_temple_id` to the user DTOs/entity (and the Core Data model), then take the name from `ordination_temple.name` of `GET /v1/users/me` after sign-in; update the Otp/Login repository tests that assert `ordinationPlace`.
VI: Thêm `ordination_temple_id` vào DTO/entity user (và model Core Data), rồi lấy tên từ `ordination_temple.name` của `GET /v1/users/me` sau đăng nhập; cập nhật test repository Otp/Login đang assert `ordinationPlace`.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
