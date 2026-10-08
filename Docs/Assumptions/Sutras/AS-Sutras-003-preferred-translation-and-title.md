---
id: AS-Sutras-003
title: Titles prefer vi → en → pli; the shown translation is the first Vietnamese one
title_vi: Tên kinh ưu tiên vi → en → pli; bản dịch hiển thị là bản tiếng Việt đầu tiên
feature: Sutras
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Data/DTOs/Mappers/ILSutraMapper.swift
source: BE contract (titles per language; translations[] with several variants per language)
owner: Product / BA
---

## Assumption / Giả định
EN: The title is `titles.vi`, else `en`, else `pli`, else any other language, else the slug. The original name is the Pāli (else English) title when it differs from the title. Translator, source, license and line count come from the first translation with `lang == "vi"` (server order), otherwise the first translation. For sutras with several Vietnamese variants (e.g. Tâm Kinh: `vi-chant`, `vi-meaning`, ...) the first listed one is used. The app language is not consulted.
VI: Tên kinh là `titles.vi`, rồi `en`, rồi `pli`, rồi ngôn ngữ khác, rồi slug. Tên nguyên ngữ là tên Pāli (hoặc Anh) khi khác tên chính. Dịch giả, nguồn, giấy phép và số dòng lấy từ bản dịch `lang == "vi"` đầu tiên (theo thứ tự server), nếu không có thì bản đầu tiên. Với kinh có nhiều bản tiếng Việt (vd. Tâm Kinh: `vi-chant`, `vi-meaning`, ...) dùng bản đầu tiên. Ngôn ngữ của app không được xét.

## Rationale / Cơ sở giả định
EN: The app is Vietnamese-first and the server lists translations in its own priority order.
VI: App ưu tiên tiếng Việt và server liệt kê bản dịch theo thứ tự ưu tiên riêng.

## Implications if wrong / Hệ quả nếu sai
EN: A different Vietnamese variant (e.g. the chanting text vs. the meaning) may be what users expect; the translator / license shown may not match the text the Reader will later show.
VI: Người dùng có thể mong bản tiếng Việt khác (vd. bản tụng thay vì bản nghĩa); dịch giả / giấy phép hiển thị có thể không khớp với văn bản Reader sẽ hiện sau này.

## Validation / Cách xác nhận
EN: Product / BA to decide which variant is the default and whether the user can switch translation.
VI: Product / BA quyết định bản mặc định và việc người dùng có được đổi bản dịch hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
