---
id: TD-Language-001
title: Chosen language is persisted but does not change any UI text
title_vi: Ngôn ngữ đã chọn được lưu nhưng chưa làm đổi chữ trên UI
feature: Language
level: Medium
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/Language/ILLanguageUseCase.swift:35
  - InnerLamp/Core/Localization/LocalizationConfig.swift:15
---

## Description / Mô tả
EN: `ILLanguageUseCaseImpl.apply` stores the language code in UserDefaults, but `LocalizationServiceImpl` still loads `LocalizationConfig.defaultLanguage` ("vi") and only `vi.json` exists. Selecting English or 中文 · 繁體 therefore changes nothing visible.
VI: `ILLanguageUseCaseImpl.apply` lưu mã ngôn ngữ vào UserDefaults, nhưng `LocalizationServiceImpl` vẫn nạp "vi" và chỉ có `vi.json`. Chọn English hoặc 中文 · 繁體 chưa làm thay đổi gì trên UI.

## Why it was taken on / Lý do chấp nhận nợ
EN: No translation files exist and the i18n server is mocked; the Language screen was built first as the UI + preference storage.
VI: Chưa có file dịch và server i18n đang mock; màn Ngôn ngữ được làm trước phần UI + lưu lựa chọn.

## Impact / Ảnh hưởng
EN: Users can pick a language that has no effect. Strings are read at view creation, so a live switch also needs a re-render or app restart strategy.
VI: Người dùng chọn được ngôn ngữ nhưng không có tác dụng. Chuỗi được đọc lúc tạo view nên đổi ngôn ngữ trực tiếp cần chiến lược render lại hoặc khởi động lại app.

## Proposed fix / Hướng xử lý
EN: Add `en.json` / `zh-Hant.json`; make `LocalizationServiceImpl` read the stored language (falling back to "vi" when its file is missing); decide between restart prompt and live refresh.
VI: Thêm `en.json` / `zh-Hant.json`; cho `LocalizationServiceImpl` đọc ngôn ngữ đã lưu (fallback "vi" nếu thiếu file); chọn giữa nhắc khởi động lại và làm mới trực tiếp.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
