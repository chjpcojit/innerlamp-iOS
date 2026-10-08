---
id: AS-Language-001
title: Traditional Chinese is stored and bundled as "zh-Hant"
title_vi: Tiếng Trung phồn thể được lưu và đặt tên file là "zh-Hant"
feature: Language
level: Low
status: Unvalidated
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Domain/Entities/ILLanguageEntity.swift:12
source: Docs/Specs/Language/requirements.md (language list, no code given)
owner: Product / BA
---

## Assumption / Giả định
EN: The three languages use the codes `vi`, `en`, `zh-Hant`; these double as the localization file names and any future server language parameter.
VI: Ba ngôn ngữ dùng mã `vi`, `en`, `zh-Hant`; đồng thời là tên file localization và tham số ngôn ngữ phía server sau này.

## Rationale / Cơ sở giả định
EN: The spec only lists display names; BCP-47 codes are the iOS convention and `vi` already matches `LocalizationConfig.defaultLanguage`.
VI: Spec chỉ liệt kê tên hiển thị; mã BCP-47 là quy ước iOS và `vi` đã khớp `LocalizationConfig.defaultLanguage`.

## Implications if wrong / Hệ quả nếu sai
EN: Rename the raw value (and migrate stored values) once the i18n server's codes are known.
VI: Đổi raw value (và migrate giá trị đã lưu) khi biết mã của server i18n.

## Validation / Cách xác nhận
EN: Confirm the language codes with the i18n backend owner.
VI: Xác nhận mã ngôn ngữ với bên phụ trách backend i18n.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
