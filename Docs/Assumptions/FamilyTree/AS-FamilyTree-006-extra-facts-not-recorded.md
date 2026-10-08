---
id: AS-FamilyTree-006
title: Extra facts are shown only when they apply, as "Chưa cập nhật" when empty
title_vi: Các dòng thông tin thêm chỉ hiện khi phù hợp, hiện "Chưa cập nhật" khi trống
feature: FamilyTree
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift
  - InnerLamp/Presentation/Scenes/FamilyTree/Views/ILFamilyTreeDetailSheetView.swift
source: Docs/Specs/FamilyTree/requirements.md (v2.0 extra fact rows, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: "Đang sống tại" is shown for living members only, "Nơi an táng" and "Bài vị thờ tại" for deceased members only, "Pháp danh" for everyone; every row reads "Chưa cập nhật" while no data source exists (the temple row becomes an underlined link once a temple is present).
VI: "Đang sống tại" chỉ hiện cho người còn sống, "Nơi an táng" và "Bài vị thờ tại" chỉ cho người đã mất, "Pháp danh" cho mọi người; mọi dòng hiện "Chưa cập nhật" khi chưa có nguồn dữ liệu (dòng chùa thành liên kết gạch chân khi có chùa).

## Rationale / Cơ sở giả định
EN: The design only renders those rows when data exists and gates residence/burial by living/deceased; the task asks to show the empty placeholder instead of hiding the rows.
VI: Design chỉ hiện các dòng này khi có dữ liệu và tách nơi sống/an táng theo còn sống/đã mất; yêu cầu là hiện placeholder thay vì ẩn dòng.

## Implications if wrong / Hệ quả nếu sai
EN: Rows may need to be hidden instead of showing a placeholder, or shown for other member states.
VI: Có thể phải ẩn dòng thay vì hiện placeholder, hoặc hiện cho trạng thái thành viên khác.

## Validation / Cách xác nhận
EN: Design review with Product / BA on a device.
VI: Design review cùng Product / BA trên thiết bị.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
