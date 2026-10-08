---
id: AS-Core-001
title: Dev backend is reached via the Mac's mDNS hostname instead of a LAN IP
title_vi: Backend dev được truy cập qua hostname mDNS của Mac thay vì IP LAN
feature: Core
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Core/Networking/APIConfig.swift:41
  - InnerLamp/Info.plist:13
source: Verbal request from user (2026-10-07), BE confirmed http://<host>:8080 plain HTTP
owner: iOS dev
---

## Assumption / Giả định
EN: The physical device and the Mac running the backend are on the same network, and the device can resolve `WeeDigitals-MacBook-Pro.local` via mDNS/Bonjour. Verified only from the Mac itself (HTTP 404 from `/`), not from a device.
VI: Thiết bị thật và Mac chạy backend cùng mạng, và thiết bị phân giải được `WeeDigitals-MacBook-Pro.local` qua mDNS/Bonjour. Mới kiểm chứng từ chính Mac (HTTP 404 ở `/`), chưa kiểm chứng từ thiết bị.

## Rationale / Cơ sở giả định
EN: The LAN IP changes with every Wi-Fi network, forcing a code + Info.plist edit each run. The `.local` hostname is stable across networks.
VI: IP LAN đổi theo từng mạng Wi-Fi, mỗi lần chạy phải sửa code + Info.plist. Hostname `.local` không đổi khi đổi mạng.

## Implications if wrong / Hệ quả nếu sai
EN: API calls fail or hang until timeout (e.g. on networks that block mDNS/client isolation, or if the Mac is renamed). Fallback: use the Mac's current IP.
VI: Gọi API lỗi hoặc treo tới timeout (mạng chặn mDNS/client isolation, hoặc đổi tên Mac). Cách xử lý tạm: dùng IP hiện tại của Mac.

## Validation / Cách xác nhận
EN: Run the app on a physical device on the same Wi-Fi and confirm catalog requests succeed; allow the Local Network permission prompt.
VI: Chạy app trên thiết bị thật cùng Wi-Fi, xác nhận request catalog thành công; cho phép quyền Local Network khi được hỏi.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated)_
VI: _(điền khi Validated/Invalidated)_
