---
id: AS-Festivals-002
title: Festivals screen shows every server event and keeps local Rằm/Mùng Một observances
title_vi: Màn Lịch lễ hiển thị mọi sự kiện của server và vẫn tự tính ngày trai giới Rằm/Mùng Một
feature: Festivals
level: Medium
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Domain/UseCases/Festivals/ILFestivalsUseCase.swift
source: User request 2026-10-11 (Festivals must read events from the API); backend docs/specs/features/calendar/api-contract.md v2.1
owner: Product / BA
---

## Assumption / Giả định
EN: Every occurrence returned by `GET /v1/calendar/events?year=` is shown (all groups, including `folk`; the earlier local filter that dropped folk and Theravada events is gone). On days with no server occurrence, Rằm (lunar 15) and Mùng Một (lunar 1) are still added client-side as "ngày trai giới" using `ILLunarCalendar`, because the server contract does not guarantee those days. If the server later emits them as events they show as festivals and the local entry is skipped for that day.
VI: Mọi lần xuất hiện server trả về đều được hiển thị (mọi nhóm, kể cả `folk`; bộ lọc cục bộ cũ loại Tết dân gian và lễ Nam tông đã bỏ). Với ngày không có sự kiện server, Rằm (15 âm) và Mùng Một (1 âm) vẫn được client thêm là "ngày trai giới" bằng `ILLunarCalendar` vì contract server không đảm bảo các ngày này. Nếu server sau này trả chúng thành sự kiện thì hiện là lễ và client bỏ mục tự tính của ngày đó.

## Rationale / Cơ sở giả định
EN: The request asked to read all events of the year from the API; matching the Home carousel (AS-Home-003) keeps both screens consistent. Dropping the observances would empty the "Rằm & Mùng Một" tab.
VI: Yêu cầu là đọc toàn bộ sự kiện của năm từ API; khớp carousel Trang chủ (AS-Home-003) để hai màn nhất quán. Bỏ ngày trai giới sẽ làm trống tab "Rằm & Mùng Một".

## Implications if wrong / Hệ quả nếu sai
EN: If Product wants only Buddhist-group events here, filter on `groupCodes.contains("buddhist")` in the UseCase. If the server already returns Rằm/Mùng Một, the observance tab may lose entries or duplicate wording.
VI: Nếu Product chỉ muốn sự kiện nhóm Phật giáo, lọc theo `groupCodes.contains("buddhist")` trong UseCase. Nếu server đã trả Rằm/Mùng Một, tab ngày trai giới có thể mất mục hoặc trùng cách gọi.

## Validation / Cách xác nhận
EN: Confirm with Product/BE which groups the screen should show and whether the server emits Rằm/Mùng Một.
VI: Xác nhận với Product/BE nhóm nào hiển thị ở màn này và server có trả Rằm/Mùng Một hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
