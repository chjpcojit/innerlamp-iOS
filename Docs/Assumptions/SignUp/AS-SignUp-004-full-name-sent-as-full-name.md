---
id: AS-SignUp-004
title: Full name is sent as `full_name` on register request-otp
title_vi: Họ và tên được gửi bằng trường `full_name` khi đăng ký
feature: SignUp
level: High
status: Validated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/DTOs/ILSignUpDTO.swift
  - InnerLamp/Data/DTOs/Mappers/ILSignUpMapper.swift
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewModel.swift
source: Docs/innerlamp-project/project/InnerLamp Prototype.dc.html (isSignup "Họ và tên"), Docs/Specs/SignUp/requirements.md (v1.15, ⚠️ Not confirmed)
owner: Product / Backend
---

## Assumption / Giả định
EN: `POST /v1/auth/register/request-otp` accepts a string `full_name` (the trimmed, required "Họ và tên" field) next to `dharma_name`. The key name was chosen by the product owner; the backend code/openapi did not list it when this was written.
VI: `POST /v1/auth/register/request-otp` nhận chuỗi `full_name` (ô "Họ và tên" bắt buộc, đã trim) bên cạnh `dharma_name`. Tên key do chủ sản phẩm chọn; lúc viết, code/openapi backend chưa liệt kê trường này.

## Rationale / Cơ sở giả định
EN: The prototype's sign-up screen has a required full-name field; the existing contract only carries the dharma name.
VI: Màn đăng ký trong prototype có ô họ và tên bắt buộc; hợp đồng hiện tại chỉ có pháp danh.

## Implications if wrong / Hệ quả nếu sai
EN: The server decodes the body strictly, so an unknown key returns `400 VALIDATION_ERROR` and every registration from the app fails until the backend accepts `full_name` (or the key is renamed).
VI: Server giải mã body chặt nên key lạ trả `400 VALIDATION_ERROR`, mọi lượt đăng ký từ app sẽ lỗi cho đến khi backend nhận `full_name` (hoặc đổi tên key).

## Validation / Cách xác nhận
EN: Ask backend to add `full_name` to the register request (and whether it is required/max length), then run one real sign-up against staging.
VI: Nhờ backend thêm `full_name` vào request đăng ký (và xác nhận bắt buộc/độ dài tối đa), rồi đăng ký thử thật trên staging.

## Outcome / Kết luận
EN: Validated 2026-10-11 by the backend session (checked against its code and openapi): key `full_name`, required, trimmed + NFC, max 300 characters; missing -> `400 VALIDATION_ERROR`, blank / too long -> `400 INVALID_FULL_NAME`. Caveat: the backend change was still uncommitted in its working tree (local dev server only) — re-check once it is deployed to staging.
VI: Đã xác nhận 2026-10-11 bởi session backend (đối chiếu code và openapi): key `full_name`, bắt buộc, trim + NFC, tối đa 300 ký tự; thiếu -> `400 VALIDATION_ERROR`, rỗng / quá dài -> `400 INVALID_FULL_NAME`. Lưu ý: thay đổi backend lúc đó chưa commit (chỉ server dev local) — kiểm tra lại khi lên staging.
