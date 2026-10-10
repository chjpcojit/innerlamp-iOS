---
id: AS-SignUp-002
title: Ordination place is sent as the temple name
title_vi: Nơi xuất gia được gửi bằng tên chùa
feature: SignUp
level: Medium
status: Unvalidated
created: 2026-10-10
updated: 2026-10-10
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
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
