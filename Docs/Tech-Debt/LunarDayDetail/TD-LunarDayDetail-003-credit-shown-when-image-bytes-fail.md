---
id: TD-LunarDayDetail-003
title: Credit line stays visible if the image bytes fail to load
title_vi: Dòng ghi công vẫn hiện khi tải ảnh thất bại
feature: LunarDayDetail
level: Low
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Presentation/Scenes/LunarDayDetail/Views/ILLunarDayDetailHeroView.swift
---

## Description / Mô tả
EN: ILRemoteImageView has no completion callback, so the caption is shown whenever the JSON call succeeded, even if the JPEG then fails (404, wrong LAN IP) and the gradient stays.
VI: ILRemoteImageView không có callback hoàn tất, nên caption hiện mỗi khi gọi JSON thành công, kể cả khi JPEG tải lỗi (404, sai IP LAN) và hero vẫn là gradient.

## Why it was taken on / Lý do chấp nhận nợ
EN: Adding a completion API to a shared design-system component was out of scope for this feature.
VI: Thêm API hoàn tất cho component dùng chung nằm ngoài phạm vi tính năng này.

## Impact / Ảnh hưởng
EN: A credit for a picture the user cannot see; cosmetic.
VI: Hiện ghi công cho ảnh người dùng không thấy; chỉ ảnh hưởng thẩm mỹ.

## Proposed fix / Hướng xử lý
EN: Give ILRemoteImageView an optional onLoaded(Bool) closure and hide the caption on failure.
VI: Thêm closure onLoaded(Bool) tùy chọn cho ILRemoteImageView và ẩn caption khi lỗi.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
