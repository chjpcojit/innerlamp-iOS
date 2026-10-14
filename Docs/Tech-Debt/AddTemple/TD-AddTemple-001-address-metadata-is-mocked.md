---
id: TD-AddTemple-001
title: Province / ward dropdown data is a local mock
title_vi: Dữ liệu dropdown tỉnh / phường-xã đang là dữ liệu mẫu cục bộ
feature: AddTemple
level: Medium
status: Resolved
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/App/DIContainer.swift
  - InnerLamp/Domain/UseCases/AddTemple/ILAddTempleUseCase.swift
---

## Description / Mô tả
EN: The "Thêm thông tin chùa" province and ward dropdowns read from `ILAddressMetadataRepository`, which is wired to `ILMockAddressMetadataRepository` (34 provinces, wards for 4 cities only, other provinces return 3 placeholder wards, artificial delay).
VI: Dropdown tỉnh và phường/xã của "Thêm thông tin chùa" đọc từ `ILAddressMetadataRepository`, hiện nối với `ILMockAddressMetadataRepository` (34 tỉnh, phường/xã chỉ có cho 4 thành phố, tỉnh khác trả 3 phường mẫu, có độ trễ giả).

## Why it was taken on / Lý do chấp nhận nợ
EN: The request was UI first; the metadata API contract is not confirmed yet.
VI: Yêu cầu làm UI trước; hợp đồng API metadata chưa được xác nhận.

## Impact / Ảnh hưởng
EN: Users can only pick from sample wards; a proposal may carry a placeholder ward for most provinces.
VI: Người dùng chỉ chọn được phường/xã mẫu; đề xuất có thể mang phường giả với đa số tỉnh.

## Proposed fix / Hướng xử lý
EN: Add a remote `ILAddressMetadataRepository` implementation once the metadata endpoints are confirmed, swap it in `DIContainer.makeAddTempleUseCase`, keep the mock for tests, and delete the placeholder-ward fallback.
VI: Thêm bản cài đặt remote của `ILAddressMetadataRepository` khi endpoint metadata được xác nhận, thay trong `DIContainer.makeAddTempleUseCase`, giữ mock cho test và bỏ nhánh phường giả.

## Resolution / Kết quả xử lý
EN: Resolved 2026-10-11. `ILAddTempleUseCaseImpl` now reads `ILAdministrativeUnitRepository` (`GET /v1/administrative-units/new/provinces` and `.../provinces/{code}/wards`); the mock and `ILAddressMetadataRepository` were deleted.
VI: Đã xử lý 2026-10-11. `ILAddTempleUseCaseImpl` đọc `ILAdministrativeUnitRepository` (`GET /v1/administrative-units/new/provinces` và `.../provinces/{code}/wards`); đã xoá mock và `ILAddressMetadataRepository`.
