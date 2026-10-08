---
id: TD-LunarDayDetail-002
title: Hero image host is the backend dev LAN IP
title_vi: Host ảnh hero là IP LAN của backend dev
feature: LunarDayDetail
level: High
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Core/Networking/APIConfig.swift
---

## Description / Mô tả
EN: image_url is an absolute URL on the dev backend (static files read from the backend's disk, host = the Mac's LAN IP). It is used verbatim, so it only works on the same Wi-Fi while the backend runs.
VI: image_url là URL tuyệt đối trên backend dev (file tĩnh đọc từ đĩa backend, host = IP LAN của Mac). App dùng nguyên văn nên chỉ chạy khi cùng Wi-Fi và backend đang chạy.

## Why it was taken on / Lý do chấp nhận nợ
EN: The backend serves these images dev-only for now; staging/production hosting and a CDN do not exist yet.
VI: Hiện backend chỉ phục vụ ảnh dev; chưa có hosting staging/production và CDN.

## Impact / Ảnh hưởng
EN: Outside the dev setup the hero always falls back to the gradient; the feature is invisible in release builds.
VI: Ngoài môi trường dev, hero luôn rơi về gradient; tính năng không hiện ở bản release.

## Proposed fix / Hướng xử lý
EN: Backend moves the 100 images to real hosting (CDN) and returns https URLs; no iOS change needed since the URL is used verbatim. Also replace the mock staging/production APIConfig hosts.
VI: Backend chuyển 100 ảnh lên hosting thật (CDN) và trả URL https; iOS không phải sửa vì dùng URL nguyên văn. Đồng thời thay host mock staging/production trong APIConfig.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
