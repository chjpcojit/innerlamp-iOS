---
id: AS-Onboarding-001
title: Wording of the "registration in progress" message
title_vi: Nội dung thông báo "đang có đăng ký chờ xác minh"
feature: Onboarding
level: Low
status: Validated
created: 2026-10-16
updated: 2026-10-16
files:
  - Docs/Specs/Onboarding/requirements.md
source: Docs/Specs/Onboarding/requirements.md (criterion 16a; confirmed in innerlamp-be docs/product/onboarding/product.md @ v1.6)
owner: Product / BA
---

## Assumption / Giả định
EN: When `register/request-otp` answers `409 REGISTRATION_IN_PROGRESS`, iOS stays on SignUp, keeps every value and shows a localized message saying another registration for this email is waiting for its code and to try again after `details.retry_after_seconds`. Neither the product spec (@ v1.5) nor the backend names the user-facing copy.
VI: Khi `register/request-otp` trả `409 REGISTRATION_IN_PROGRESS`, iOS ở lại màn đăng ký, giữ nguyên mọi giá trị và hiện thông báo (đã localize) rằng email này đang có một bản đăng ký khác chờ mã, thử lại sau `details.retry_after_seconds` giây. Product spec (@ v1.5) và backend đều chưa nêu nội dung hiển thị.

## Rationale / Cơ sở giả định
EN: openapi 2.1.0 defines the code and `retry_after_seconds`; the product spec has no scenario for it. The behavior (stay, keep values, show the wait) follows the neighboring error rules.
VI: openapi 2.1.0 định nghĩa mã lỗi và `retry_after_seconds`; product spec chưa có kịch bản cho trường hợp này. Hành vi (ở lại, giữ giá trị, hiện thời gian chờ) theo các quy tắc lỗi lân cận.

## Implications if wrong / Hệ quả nếu sai
EN: Only the message text and, at most, where it appears change. One string and one mapping.
VI: Chỉ đổi nội dung thông báo và nhiều nhất là vị trí hiển thị. Một chuỗi và một ánh xạ lỗi.

## Validation / Cách xác nhận
EN: Ask the product owner (via `ba-writer` in innerlamp-be) to add the scenario and copy to `docs/product/onboarding/product.md`.
VI: Nhờ product owner (qua `ba-writer` ở innerlamp-be) bổ sung kịch bản và nội dung vào `docs/product/onboarding/product.md`.

## Outcome / Kết luận
EN: Validated 2026-10-16. anh Đức accepted this proposal (relayed by the backend session); product spec onboarding v1.6 (BR-ONB-08, FR-ONB-003) states it. The message reads "Vui lòng chờ N giây rồi thử lại", N from `details.retry_after_seconds`.
VI: Đã xác nhận 2026-10-16. Anh Đức chấp nhận đề xuất này (phiên backend chuyển lời); product spec onboarding v1.6 (BR-ONB-08, FR-ONB-003) đã ghi. Thông báo: "Vui lòng chờ N giây rồi thử lại", N lấy từ `details.retry_after_seconds`.
