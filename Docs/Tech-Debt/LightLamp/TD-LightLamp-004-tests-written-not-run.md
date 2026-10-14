---
id: TD-LightLamp-004
title: LightLamp unit tests are written but have not been executed
title_vi: Unit test LightLamp đã viết nhưng chưa chạy
feature: LightLamp
level: Medium
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLampTests/ILLightLampUseCaseTests.swift:1
  - InnerLampTests/ILLightLampViewModelTests.swift:1
  - InnerLampTests/ILLampGardenViewModelTests.swift:1
---

## Description / Mô tả
EN: The three test files type-check against the built module but were not run: `xcodebuild test` needs a device/simulator and the test target currently fails to build its gRPC test modules (`GRPCProtobuf`, `GRPCInProcessTransport`, plugin validation).
VI: Ba file test qua type-check với module đã build nhưng chưa chạy: `xcodebuild test` cần thiết bị/simulator và test target hiện không build được các module test gRPC (`GRPCProtobuf`, `GRPCInProcessTransport`, plugin validation).

## Why it was taken on / Lý do chấp nhận nợ
EN: No device was available and running a simulator is forbidden by AGENTS.md; the gRPC test-target problem pre-exists.
VI: Không có thiết bị và AGENTS.md cấm chạy simulator; lỗi test target gRPC đã có từ trước.

## Impact / Ảnh hưởng
EN: Failures in the new tests would only show up on the user's first test run.
VI: Lỗi trong test mới chỉ lộ ra ở lần chạy test đầu tiên của người dùng.

## Proposed fix / Hướng xử lý
EN: Run `ILLightLampUseCaseTests`, `ILLightLampViewModelTests`, `ILLampGardenViewModelTests` on a device once the gRPC test target builds.
VI: Chạy `ILLightLampUseCaseTests`, `ILLightLampViewModelTests`, `ILLampGardenViewModelTests` trên thiết bị khi test target gRPC build được.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
