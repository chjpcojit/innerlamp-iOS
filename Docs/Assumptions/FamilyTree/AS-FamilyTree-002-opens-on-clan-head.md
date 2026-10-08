---
id: AS-FamilyTree-002
title: The tree opens on the clan head, else the founder
title_vi: Cây mở ra ở tộc trưởng, nếu không có thì ở thủy tổ
feature: FamilyTree
level: Low
status: Unvalidated
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Presentation/Scenes/FamilyTree/ILFamilyTreeViewModel.swift:197
source: Gia Pha Mobile.dc.html (initial `sel: 'p13'`, the clan head)
owner: Product / BA
---

## Assumption / Giả định
EN: The prototype hard-codes the initially selected person (the clan head). With real data the first member flagged `isClanHead` is selected, falling back to the founder.
VI: Prototype gán cứng người được chọn ban đầu (tộc trưởng). Với dữ liệu thật, thành viên đầu tiên có cờ `isClanHead` được chọn, nếu không có thì chọn thủy tổ.

## Rationale / Cơ sở giả định
EN: The clan head is the person who keeps the book, so it is the natural starting point.
VI: Tộc trưởng là người giữ gia phả nên là điểm bắt đầu tự nhiên.

## Implications if wrong / Hệ quả nếu sai
EN: Users would land on the wrong person; trivial to change.
VI: Người dùng sẽ vào nhầm người; dễ đổi.

## Validation / Cách xác nhận
EN: Ask Product whether it should instead open on the signed-in user's own record.
VI: Hỏi Product xem có nên mở ở hồ sơ của chính người dùng đang đăng nhập không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
