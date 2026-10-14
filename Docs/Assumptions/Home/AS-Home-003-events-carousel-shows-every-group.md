---
id: AS-Home-003
title: Events carousel shows every server group and derives tone from groups
title_vi: Carousel sự kiện hiển thị mọi nhóm của server và suy ra tông màu từ nhóm
feature: Home
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Home/ILHomeUseCase.swift
source: Backend docs/specs/features/calendar/api-contract.md v2.1 (no client-facing rule for the Home carousel)
owner: Product / BA
---

## Assumption / Giả định
EN: The Home carousel "Sự kiện Phật giáo" shows every occurrence the server returns for the year (groups `buddhist`, `vietnam`, `folk`), with no group filter. Tone: group `buddhist` → gold, `folk` → green, anything else → rose. Rằm and Mùng 1 appear every lunar month and share the 3-row cap per month card.
VI: Carousel "Sự kiện Phật giáo" hiển thị mọi occurrence server trả về trong năm (nhóm `buddhist`, `vietnam`, `folk`), không lọc nhóm. Tông màu: nhóm `buddhist` → vàng, `folk` → xanh, còn lại → hồng. Rằm và Mùng 1 lặp mỗi tháng âm và dùng chung giới hạn 3 dòng mỗi thẻ tháng.

## Rationale / Cơ sở giả định
EN: The previous local catalogue also mixed Buddhist and folk holidays without filtering, and the API contract gives no rule. Keeping the old behaviour avoids an unrequested change.
VI: Catalog cục bộ trước đây cũng trộn lễ Phật giáo và Tết dân gian, không lọc; contract API không nêu quy tắc. Giữ hành vi cũ để không đổi ngoài yêu cầu.

## Implications if wrong / Hệ quả nếu sai
EN: Non-Buddhist holidays (e.g. Tết Dương lịch) or the 24 monthly Rằm/Mùng 1 rows may crowd out major Buddhist events inside the 3-row cap. Fix is a one-line filter/priority in `loadBuddhistEventMonths`.
VI: Ngày lễ không thuộc Phật giáo hoặc 24 dòng Rằm/Mùng 1 hằng tháng có thể chiếm chỗ lễ Phật giáo lớn trong giới hạn 3 dòng. Sửa bằng một bộ lọc/ưu tiên trong `loadBuddhistEventMonths`.

## Validation / Cách xác nhận
EN: Show the carousel for a few months on device and confirm the group filter and ordering with Product.
VI: Xem carousel vài tháng trên thiết bị và chốt bộ lọc nhóm, thứ tự với Product.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
