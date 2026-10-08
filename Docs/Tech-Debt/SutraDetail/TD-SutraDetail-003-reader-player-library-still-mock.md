---
id: TD-SutraDetail-003
title: Reader, Player and the Library "Kinh Pháp Cú" item still use mock sutra ids
title_vi: Reader, Player và mục "Kinh Pháp Cú" của Library vẫn dùng id kinh mock
feature: SutraDetail
level: High
status: Open
created: 2026-10-07
updated: 2026-10-07
files:
  - InnerLamp/Domain/UseCases/Reader/ILReaderUseCase.swift:42
  - InnerLamp/Domain/UseCases/Player/ILPlayerUseCase.swift:110
  - InnerLamp/Domain/UseCases/Library/ILLibraryUseCase.swift:38
---

## Description / Mô tả
EN: SutraDetail now takes the server slug (e.g. `kinh-tu-bi`) and forwards it to Reader / Player, whose catalogs are still mock (`sutra.phapcu`, ...). An unknown id falls back to the first mock sutra, so "Tụng theo" / a chapter tap opens the wrong text. Library's items `vu-lan`, `a-di-da`, `chu-dai-bi` (and Deity's "Kinh A Di Đà") were moved to the real slugs, but Library's "Kinh Pháp Cú" (`sutra.phapcu`) has no single server match (the server splits it into 26 `phap-cu-*` entries) and now shows the not-found error in SutraDetail.
VI: SutraDetail giờ nhận slug của server (vd. `kinh-tu-bi`) và chuyển cho Reader / Player, vốn vẫn dùng catalog mock (`sutra.phapcu`, ...). Id lạ rơi về kinh mock đầu tiên, nên "Tụng theo" / chạm một phẩm sẽ mở sai nội dung. Các mục `vu-lan`, `a-di-da`, `chu-dai-bi` của Library (và "Kinh A Di Đà" ở Deity) đã đổi sang slug thật, nhưng mục "Kinh Pháp Cú" (`sutra.phapcu`) của Library không có bản tương ứng duy nhất trên server (server tách thành 26 mục `phap-cu-*`) nên hiện báo không tìm thấy ở SutraDetail.

## Why it was taken on / Lý do chấp nhận nợ
EN: Scope of this task (2026-10-07) was Sutras + SutraDetail only; Reader integration (`GET /v1/sutras/{id}/lines`) was deferred.
VI: Phạm vi task (2026-10-07) chỉ gồm Sutras + SutraDetail; tích hợp Reader (`GET /v1/sutras/{id}/lines`) để sau.

## Impact / Ảnh hưởng
EN: Wrong text in Reader / Player for every server sutra; broken "Kinh Pháp Cú" tile in Library.
VI: Reader / Player hiện sai nội dung với mọi kinh từ server; ô "Kinh Pháp Cú" ở Library bị lỗi.

## Proposed fix / Hướng xử lý
EN: Integrate Reader with `/v1/sutras/{id}/lines` (keep `page_size` constant while reading one translation); decide what the Library "Kinh Pháp Cú" tile should point to (a `phap-cu-*` entry, or a list filtered to them).
VI: Tích hợp Reader với `/v1/sutras/{id}/lines` (giữ nguyên `page_size` khi đọc một bản dịch); quyết định ô "Kinh Pháp Cú" của Library trỏ tới đâu (một mục `phap-cu-*`, hoặc danh sách lọc các mục này).

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
