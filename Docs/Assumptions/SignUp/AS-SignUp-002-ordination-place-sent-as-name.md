---
id: AS-SignUp-002
title: Ordination place is sent as the temple name
title_vi: Nơi xuất gia được gửi bằng tên chùa
feature: SignUp
level: Medium
status: Invalidated
created: 2026-10-10
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/SignUp/ILSignUpViewModel.swift
  - InnerLamp/Domain/UseCases/SignUp/ILOrdinationPlaceUseCase.swift
source: Docs/innerlamp-project/project/InnerLamp Prototype.dc.html (isSignup ordination picker, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The picker still submits `ordination_place` as a plain string: the chosen temple's name, or an empty string for "Chưa xuất gia". The server does not need a temple id. The list is the full public catalog (`GET /v1/temples`), and the row subtitle shows the temple's address.
VI: Bộ chọn vẫn gửi `ordination_place` là chuỗi: tên chùa đã chọn, hoặc chuỗi rỗng khi chọn "Chưa xuất gia". Server không cần id chùa. Danh sách là toàn bộ danh bạ công khai (`GET /v1/temples`), dòng phụ hiển thị địa chỉ chùa.

## Rationale / Cơ sở giả định
EN: The existing sign-up contract only has the string field; the prototype shows district/province under the name, which the catalog summary only offers as a single address.
VI: Hợp đồng đăng ký hiện chỉ có trường chuỗi; prototype hiện quận/tỉnh dưới tên nhưng danh bạ chỉ có một địa chỉ.

## Implications if wrong / Hệ quả nếu sai
EN: If the backend expects a temple id, or links the account to the temple, registrations would keep only a free-text name.
VI: Nếu backend cần id chùa hoặc liên kết tài khoản với chùa thì đăng ký chỉ lưu được tên dạng văn bản.

## Validation / Cách xác nhận
EN: Confirm with backend whether `ordination_place` should carry a temple id or stay free text.
VI: Xác nhận với backend `ordination_place` có cần mang id chùa hay giữ dạng văn bản.

## Outcome / Kết luận
EN: Invalidated 2026-10-11 by the backend session. `POST /v1/auth/register/request-otp` rejects `ordination_place` (strict body decoding → `400 VALIDATION_ERROR`) and only accepts `ordination_temple_id`, an id from `GET /v1/temples/options`. The picker now sends that id (omitted for "Chưa xuất gia"). See `Docs/Specs/SignUp/` v1.14.
VI: Bị bác bỏ ngày 2026-10-11 bởi session backend. `POST /v1/auth/register/request-otp` từ chối `ordination_place` (giải mã body chặt → `400 VALIDATION_ERROR`) và chỉ nhận `ordination_temple_id`, là id lấy từ `GET /v1/temples/options`. Bộ chọn giờ gửi id đó (bỏ field khi chọn "Chưa xuất gia"). Xem `Docs/Specs/SignUp/` v1.14.
