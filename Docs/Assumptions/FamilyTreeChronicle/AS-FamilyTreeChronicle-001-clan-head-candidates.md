---
id: AS-FamilyTreeChronicle-001
title: Clan-head candidates are living men of the blood line below the founder
title_vi: Ứng viên tộc trưởng là nam còn sống thuộc huyết thống, từ đời 2
feature: FamilyTreeChronicle
level: Medium
status: Unvalidated
created: 2026-10-04
updated: 2026-10-04
files:
  - InnerLamp/Domain/UseCases/FamilyTreeChronicle/ILFamilyTreeChronicleUseCase.swift:127
source: Docs/InnerLamp project/IL-GiaPha.dc.html (`cands` in `pkVals`, not a confirmed business rule)
owner: Product / BA
---

## Assumption / Giả định
EN: Only living men who are not married-in and sit in generation 2 or later can become clan head, oldest generation first then oldest by birth year.
VI: Chỉ nam còn sống, không phải dâu/rể và thuộc đời 2 trở đi mới được làm tộc trưởng, xếp theo đời nhỏ trước rồi theo năm sinh.

## Rationale / Cơ sở giả định
EN: Taken from the prototype and its hint "Theo lệ, tộc trưởng thường là con trai trưởng của chi trưởng".
VI: Lấy từ prototype và dòng gợi ý "Theo lệ, tộc trưởng thường là con trai trưởng của chi trưởng".

## Implications if wrong / Hệ quả nếu sai
EN: Some clans pick a woman, a descendant of the founder's daughter line, or the founder's generation; they could not be chosen.
VI: Một số dòng họ chọn nữ, hoặc người đời 1; những người đó sẽ không chọn được.

## Validation / Cách xác nhận
EN: Confirm the rule with Product / the clan owners; change `clanHeadCandidates` in the UseCase.
VI: Xác nhận quy tắc với Product / chủ dòng họ; sửa `clanHeadCandidates` trong UseCase.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
