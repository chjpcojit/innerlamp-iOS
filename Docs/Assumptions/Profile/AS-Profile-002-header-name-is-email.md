---
id: AS-Profile-002
title: Profile header name is the account email
title_vi: Tên hiển thị ở đầu trang Hồ sơ là email tài khoản
feature: Profile
level: Low
status: Invalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Profile/ILProfileUseCase.swift
source: Docs/Specs/Profile/requirements.md (header name, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: `GET /v1/users/me` has no full name, so the profile header shows the account email as the name (initial = first letter of the email) and the dharma name in the subtitle.
VI: `GET /v1/users/me` không có họ tên, nên đầu trang Hồ sơ hiện email tài khoản làm tên (chữ cái đầu = ký tự đầu của email) và pháp danh ở dòng phụ.

## Rationale / Cơ sở giả định
EN: Email is the only always-present identity field the backend returns; phone is E.164 and less friendly.
VI: Email là trường định danh duy nhất luôn có mà backend trả về; số điện thoại dạng E.164 kém thân thiện hơn.

## Implications if wrong / Hệ quả nếu sai
EN: Header looks odd (an email as a name). Cosmetic; one line to change.
VI: Đầu trang trông lạ (email làm tên). Chỉ là thẩm mỹ, sửa một dòng.

## Validation / Cách xác nhận
EN: Ask product what to show as the display name; if a full-name field is wanted, ask backend to add it (it can be set via `PATCH /v1/users/me`).
VI: Hỏi product nên hiện gì làm tên; nếu cần họ tên thì yêu cầu backend thêm trường (đặt qua `PATCH /v1/users/me`).

## Outcome / Kết luận
EN: Invalidated 2026-10-11: backend confirmed `GET /v1/users/me` returns `data.full_name` (absent for accounts created before it became required). The header now shows the full name and falls back to the email only when it is absent.
VI: Không còn đúng 2026-10-11: backend xác nhận `GET /v1/users/me` trả `data.full_name` (vắng mặt với tài khoản tạo trước khi trường này bắt buộc). Đầu trang giờ hiện họ tên, chỉ dùng email khi thiếu.
