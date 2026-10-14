---
id: TD-LightLamp-005
title: Elapsed lamps stay in Core Data forever
title_vi: Đèn hết hạn vẫn nằm mãi trong Core Data
feature: LightLamp
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Data/DataSources/Local/ILLampLocalDataSource.swift:17
  - InnerLamp/Domain/UseCases/LightLamp/ILLightLampUseCase.swift:50
---

## Description / Mô tả
EN: Elapsed lamps are filtered out when loading but never deleted from the store.
VI: Đèn hết hạn bị lọc khi tải nhưng không bao giờ bị xóa khỏi store.

## Why it was taken on / Lý do chấp nhận nợ
EN: Deleting is not required by the spec and a lamp history may be wanted later (e.g. a journal).
VI: Spec không yêu cầu xóa và có thể cần lịch sử đèn sau này (vd. nhật ký).

## Impact / Ảnh hưởng
EN: The table grows slowly; `loadAll` fetches every row and filters in memory.
VI: Bảng lớn dần chậm; `loadAll` đọc mọi dòng rồi lọc trong bộ nhớ.

## Proposed fix / Hướng xử lý
EN: Add a predicate on `litAt`/`durationDays` or a periodic purge once a retention rule is decided.
VI: Thêm predicate theo `litAt`/`durationDays` hoặc dọn định kỳ khi có quy tắc lưu trữ.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
