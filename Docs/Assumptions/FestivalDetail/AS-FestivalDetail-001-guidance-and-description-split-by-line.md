---
id: AS-FestivalDetail-001
title: Guidance and long description are split into items/paragraphs by line breaks
title_vi: Guidance và mô tả dài được tách thành mục/đoạn theo dòng
feature: FestivalDetail
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/FestivalDetail/ILFestivalDetailViewModel.swift
source: Docs/Specs/FestivalDetail/requirements.md (⚠️ Not confirmed)
owner: Backend / Product
---

## Assumption / Giả định
EN: `guidance` holds one practice per line (an optional leading "-", "•" or "*" is stripped) and `long_description` holds one paragraph per line. A single-line value renders as one row/paragraph.
VI: `guidance` mỗi dòng là một việc (bỏ ký tự đầu dòng "-", "•", "*" nếu có) và `long_description` mỗi dòng là một đoạn. Giá trị một dòng hiện thành một hàng/đoạn.

## Rationale / Cơ sở giả định
EN: The contract only says `guidance` is "ritual guidance; may be empty"; the prototype shows numbered rows and several paragraphs.
VI: Hợp đồng chỉ nói `guidance` là "hướng dẫn nghi lễ, có thể rỗng"; prototype hiện các hàng đánh số và nhiều đoạn.

## Implications if wrong / Hệ quả nếu sai
EN: A comma-separated guidance would show as one long row; fixable in the ViewModel only.
VI: Nếu guidance ngăn bằng dấu phẩy sẽ hiện thành một hàng dài; chỉ cần sửa ở ViewModel.

## Validation / Cách xác nhận
EN: Check real `guidance` / `long_description` values from the backend with the owner.
VI: Kiểm tra giá trị `guidance` / `long_description` thật từ backend với chủ nội dung.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
