---
id: AS-Temple-001
title: Temple image URLs are used verbatim from the API and may be absent
title_vi: URL ảnh chùa dùng nguyên văn từ API và có thể không có
feature: Temple
level: Medium
status: Unvalidated
created: 2026-10-06
updated: 2026-10-06
files:
  - InnerLamp/Presentation/Common/DesignSystem/Components/ILRemoteImageView.swift
  - InnerLamp/Presentation/Scenes/Home/Views/ILHomeTempleCarouselView.swift
  - InnerLamp/Core/Networking/APIConfig.swift:41
source: Backend session [BE]-InnerLamp message 2026-10-06 (docs/specs/features/temple/api-contract.md v1.2 is outdated on image fields)
owner: Backend
---

## Assumption / Giả định
EN: `thumbnail_url` / `image_url` are complete URLs on the dev backend (`http://<Mac LAN IP>:8080/static/images/temples/{thumb|full}/<id>.jpg`, 93/93 temples) and stay `String?` (placeholder on `nil` or HTTP 404). The app never rebuilds them. The 404 body of the static route was not verified.
VI: `thumbnail_url` / `image_url` là URL đầy đủ trên backend dev (`http://<IP LAN của Mac>:8080/static/images/temples/{thumb|full}/<id>.jpg`, 93/93 chùa) và vẫn là `String?` (hiện placeholder khi `nil` hoặc HTTP 404). App không tự dựng lại URL. Chưa kiểm body 404 của route tĩnh.

## Rationale / Cơ sở giả định
EN: The backend host is the Mac's LAN IP and changes per network, so only the string returned by the API is reliable. Production image hosting (CDN, TLS) is not defined yet.
VI: Host backend là IP LAN của Mac và đổi theo mạng, nên chỉ chuỗi do API trả về là đáng tin. Hosting ảnh production (CDN, TLS) chưa được xác định.

## Implications if wrong / Hệ quả nếu sai
EN: If production serves images from another origin, ATS / caching assumptions (HTTP 200 only, `URLSession.shared` HTTP cache) must be revisited. If the server later returns relative paths, `ILRemoteImageView` would show the placeholder only.
VI: Nếu production phục vụ ảnh từ origin khác, cần xem lại giả định ATS / cache (chỉ nhận HTTP 200, cache HTTP của `URLSession.shared`). Nếu server trả đường dẫn tương đối, `ILRemoteImageView` chỉ hiện placeholder.

## Validation / Cách xác nhận
EN: Ask backend for the production image origin and the 404 response shape of `/static/images/...`; update the contract file to v1.3.
VI: Hỏi backend về origin ảnh production và dạng response 404 của `/static/images/...`; cập nhật file contract lên v1.3.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
