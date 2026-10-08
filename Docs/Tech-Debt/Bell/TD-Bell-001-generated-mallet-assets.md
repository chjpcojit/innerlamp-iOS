---
id: TD-Bell-001
title: Mallet images are rendered, tests not executed
title_vi: Ảnh dùi được render bằng script, test chưa chạy
feature: Bell
level: Low
status: Open
created: 2026-10-03
updated: 2026-10-03
files:
  - InnerLamp/Assets.xcassets/Icons/bell_mallet_mo.imageset
  - InnerLamp/Assets.xcassets/Icons/bell_mallet_bell.imageset
---

## Description / Mô tả
EN: The design draws the mallet in CSS (gradients), so `bell_mallet_mo` / `bell_mallet_bell` were rendered with a one-off Pillow script to fit the "icons come from assets" rule; they are not designer-exported. The new UI was build-verified only (no device run, test target does not run here).
VI: Thiết kế vẽ dùi bằng CSS (gradient) nên `bell_mallet_mo` / `bell_mallet_bell` được render bằng script Pillow dùng một lần để theo quy tắc icon từ asset; không phải file designer xuất. UI mới chỉ được build, chưa chạy trên thiết bị và test chưa chạy.

## Why it was taken on / Lý do chấp nhận nợ
EN: No exported mallet artwork exists in the handoff.
VI: Handoff không có ảnh dùi xuất sẵn.

## Impact / Ảnh hưởng
EN: Mallet may look slightly different from the prototype.
VI: Dùi có thể khác nhẹ so với prototype.

## Proposed fix / Hướng xử lý
EN: Ask design for exported mallet PNG/PDF and replace the imagesets.
VI: Xin design file dùi xuất sẵn rồi thay imageset.

## Resolution / Kết quả xử lý
EN: _(open)_
VI: _(chưa xử lý)_
