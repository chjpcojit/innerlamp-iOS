---
id: AS-AddTemple-002
title: Ward is required and metadata is a flat province -> ward list
title_vi: Phường/xã bắt buộc và metadata là danh sách phẳng tỉnh -> phường/xã
feature: AddTemple
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/AddTemple/ILAddTempleUseCase.swift
  - InnerLamp/Domain/Repositories/ILAdministrativeUnitRepository.swift
source: Docs/innerlamp-project/project/InnerLamp Prototype.dc.html (isAddTp, IL-AddressPicker; ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Following the prototype, province and ward are both required and picked from metadata; wards depend on the chosen province (`loadProvinces()` and `loadWards(provinceCode:query:)`). The server returns `code` + `name` + `fullName`; the form shows province `name` and ward `fullName`, and the proposal still carries plain names only (no codes) because its submit contract is unconfirmed. The 34-province list "from 01/07/2025" is shown as the picker subtitle.
VI: Theo prototype, tỉnh và phường/xã đều bắt buộc và chọn từ metadata; phường/xã phụ thuộc tỉnh đã chọn (`provinces()` và `wards(inProvince:)`). Tên là chuỗi thuần, không có id. Phụ đề sheet hiển thị "34 tỉnh, thành · từ 01/07/2025".

## Rationale / Cơ sở giả định
EN: Mirrors the prototype's `IL-AddressPicker` and its mock `GET /meta/wards?province=…`.
VI: Khớp `IL-AddressPicker` của prototype và mock `GET /meta/wards?province=…`.

## Implications if wrong / Hệ quả nếu sai
EN: If the API returns ids/codes, the repository protocol, entity and the proposal payload need ids; if ward is optional the validation and the sign-up subtitle change.
VI: Nếu API trả id/mã thì protocol repository, entity và payload đề xuất cần thêm id; nếu phường/xã không bắt buộc thì phải đổi validate và phụ đề ở màn Đăng ký.

## Validation / Cách xác nhận
EN: Confirm the metadata endpoints and the proposal contract with backend/BA.
VI: Xác nhận endpoint metadata và hợp đồng gửi đề xuất với backend/BA.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
