---
id: AS-FamilyTree-007
title: TƯỞNG NIỆM card values are derived locally
title_vi: Giá trị thẻ TƯỞNG NIỆM được tính cục bộ
feature: FamilyTree
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeFormatter.swift
source: Docs/Specs/FamilyTree/requirements.md (TƯỞNG NIỆM card)
owner: Product / BA
---

## Assumption / Giả định
EN: The anniversary ordinal ("giỗ lần thứ N") is `max(1, current year - death year)`; the countdown targets the next solar date of the stored lunar day/month via `ILLunarCalendar`; the pill always reads "Nhắc giỗ hằng năm" (filled) when the anniversary is known and "Bổ sung ngày giỗ" (outlined) otherwise, because the tree cannot tell whether the entry already exists in the Sổ giỗ.
VI: Số lần giỗ ("giỗ lần thứ N") là `max(1, năm hiện tại - năm mất)`; đếm ngược tới ngày dương lịch kế tiếp của ngày/tháng âm đã lưu qua `ILLunarCalendar`; nút luôn là "Nhắc giỗ hằng năm" (đặc) khi biết ngày giỗ và "Bổ sung ngày giỗ" (viền) khi chưa biết, vì cây không biết mục đã có trong Sổ giỗ hay chưa.

## Rationale / Cơ sở giả định
EN: Mirrors the prototype formula (`2026 - d`) and reuses the app's lunar converter; the Sổ giỗ lookup does not exist yet (TD-FamilyTree-005).
VI: Theo công thức prototype (`2026 - d`) và dùng bộ chuyển đổi âm lịch của app; chưa có tra cứu Sổ giỗ (TD-FamilyTree-005).

## Implications if wrong / Hệ quả nếu sai
EN: Off-by-one ordinal for deaths late in the year, or a wrong pill state once the Sổ giỗ link exists.
VI: Số lần giỗ có thể lệch 1 với người mất cuối năm, hoặc sai trạng thái nút khi đã có liên kết Sổ giỗ.

## Validation / Cách xác nhận
EN: Product confirms the ordinal rule; verify the countdown against the Lunar Calendar screen.
VI: Product xác nhận quy tắc số lần giỗ; đối chiếu đếm ngược với màn Lịch âm.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
