---
id: AS-Profile-003
title: Logout clears all account-scoped local data including mock lamps; button shows to guests
title_vi: Đăng xuất xóa mọi dữ liệu cục bộ theo tài khoản gồm cả đèn mẫu; nút cũng hiện với khách
feature: Profile
level: Medium
status: Validated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Profile/ILProfileUseCase.swift
  - InnerLamp/Data/Repositories/ILSessionDataCleanerImpl.swift
  - InnerLamp/App/AppCoordinator.swift
source: Docs/Specs/Profile/requirements.md (logout, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: Logging out deletes the access and refresh tokens, the local user, the birth profile, the memorial cache, the lit lamps and the chosen temple, then shows Login. Device-level flags (onboarding seen, theme, language) and shared catalog caches are kept. The "Đăng xuất" button is shown to guest-preview users too (it just returns them to Login). Lamps are local mock data today; once a lamp API exists they come back from the server.
VI: Đăng xuất xóa access/refresh token, user cục bộ, hồ sơ ngày sinh, cache sổ tưởng niệm, đèn đã thắp và chùa đã chọn rồi hiện màn Đăng nhập. Cờ cấp thiết bị (đã xem onboarding, giao diện, ngôn ngữ) và cache danh mục dùng chung được giữ lại. Nút "Đăng xuất" cũng hiện với người dùng xem thử (chỉ đưa họ về Đăng nhập). Đèn hiện là dữ liệu mẫu cục bộ; khi có API đèn thì sẽ lấy lại từ server.

## Rationale / Cơ sở giả định
EN: Backend confirmed logout leaves the account's server data untouched and that user-scoped caches should be cleared so the next account cannot read them. Lamps are mock data (owner decision, 2026-10-11) with a server API planned, so deleting them loses nothing real.
VI: Backend xác nhận logout không đụng dữ liệu trên server và nên xóa cache theo user để tài khoản sau không đọc được. Đèn là dữ liệu mẫu (chủ dự án quyết định, 2026-10-11) và sẽ có API server, nên xóa không mất dữ liệu thật.

## Implications if wrong / Hệ quả nếu sai
EN: If lamps become real before the lamp API ships, logout would permanently delete them. Revisit when real lamp data is stored locally.
VI: Nếu đèn trở thành dữ liệu thật trước khi có API đèn thì logout sẽ xóa vĩnh viễn. Cần xem lại khi lưu đèn thật ở máy.

## Validation / Cách xác nhận
EN: Lamp deletion confirmed by the owner on 2026-10-11. Still to confirm with product: whether guests should see the button.
VI: Việc xóa đèn đã được chủ dự án xác nhận ngày 2026-10-11. Còn cần product xác nhận: khách có thấy nút này không.

## Outcome / Kết luận
EN: Validated for lamp deletion (owner, 2026-10-11): lamps are mock and will come from the server. Guest visibility of the button remains an open point.
VI: Đã xác nhận việc xóa đèn (chủ dự án, 2026-10-11): đèn là dữ liệu mẫu và sẽ lấy từ server. Việc khách có thấy nút hay không vẫn để ngỏ.
