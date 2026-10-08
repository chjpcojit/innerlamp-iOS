---
id: TD-Core-001
title: No 401 handling or token refresh in the network layer
title_vi: Chưa xử lý 401 và refresh token ở tầng network
feature: Core
level: High
status: In Progress
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Core/Networking/AuthSessionRefresher.swift
  - InnerLamp/Core/Networking/NetworkService.swift:46
  - InnerLamp/App/AppCoordinator.swift:36
  - InnerLamp/Core/GRPC/GRPCAuthInterceptor.swift
---

## Description / Mô tả
EN: `NetworkService` only maps HTTP 401 to `NetworkError.unauthorized`. There is no interceptor that refreshes the token, retries the request, or signs the user out. The stored `refresh_token` is never read. The gRPC client has the same gap.
VI: `NetworkService` chỉ map HTTP 401 thành `NetworkError.unauthorized`. Không có interceptor nào refresh token, retry request hay đăng xuất. `refresh_token` đã lưu nhưng không bao giờ được đọc. gRPC client cũng thiếu tương tự.

## Why it was taken on / Lý do chấp nhận nợ
EN: Token refresh was deferred when the networking layer was first built; the session check at Splash (open-app-straight-to-Main) makes it visible now.
VI: Refresh token được hoãn từ lúc dựng tầng network; việc Splash vào thẳng Main khi có session khiến lỗ hổng này lộ ra.

## Impact / Ảnh hưởng
EN: With an expired access token the user lands on Main and every authenticated call fails with `unauthorized`, with no recovery path except reinstalling.
VI: Khi access token hết hạn, user vào Main nhưng mọi request cần auth đều lỗi `unauthorized`, không có cách phục hồi ngoài cài lại app.

## Proposed fix / Hướng xử lý
EN: Add a 401 interceptor in `NetworkServiceImpl` (and the gRPC auth interceptor): single-flight refresh using `refresh_token`, retry once, and on refresh failure clear the Keychain session and route to Login/Onboarding.
VI: Thêm interceptor 401 trong `NetworkServiceImpl` (và gRPC auth interceptor): refresh một lần duy nhất bằng `refresh_token`, retry một lần, nếu refresh lỗi thì xóa session Keychain và chuyển về Login/Onboarding.

## Resolution / Kết quả xử lý
EN: 2026-10-07 — HTTP side done: `NetworkServiceImpl` refreshes once via `AuthSessionRefresher` (single-flight) on a 401 for authenticated requests, retries once, and on a dead session clears the Keychain and posts `.authSessionDidExpire`; `AppCoordinator` then routes to Login. **Still open: the gRPC client** (`GRPCAuthInterceptor`) does not refresh — retrying a streaming request needs its own design. Move to Resolved once gRPC is covered. Tests are written (`AuthSessionRefresherTests`) but could not be run: the `InnerLampTests` target currently fails to build on the unrelated gRPC test files (`GRPCProtobuf`/`GRPCInProcessTransport` unresolved).
VI: 2026-10-07 — Phần HTTP đã xong: `NetworkServiceImpl` refresh một lần qua `AuthSessionRefresher` (single-flight) khi request cần auth gặp 401, retry một lần; nếu session chết thì xóa Keychain và post `.authSessionDidExpire`, `AppCoordinator` chuyển về Login. **Còn mở: gRPC client** (`GRPCAuthInterceptor`) chưa refresh — retry streaming request cần thiết kế riêng. Chuyển Resolved khi xử lý xong gRPC. Test đã viết (`AuthSessionRefresherTests`) nhưng chưa chạy được: target `InnerLampTests` đang lỗi build ở các file test gRPC (`GRPCProtobuf`/`GRPCInProcessTransport` không resolve), không liên quan.
