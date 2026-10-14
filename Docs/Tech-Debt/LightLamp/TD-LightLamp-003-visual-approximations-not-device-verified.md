---
id: TD-LightLamp-003
title: Lamp artwork, stage and garden visuals are approximations not checked on device
title_vi: Hình đèn, sân khấu và vườn đèn là bản xấp xỉ chưa kiểm tra trên thiết bị
feature: LightLamp
level: Low
status: Open
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/LightLamp/Views/ILLampArtView.swift:1
  - InnerLamp/Presentation/Scenes/LightLamp/Views/ILLampStageView.swift:1
  - InnerLamp/Presentation/Scenes/LightLamp/ILLampGardenViewController.swift:1
---

## Description / Mô tả
EN: The lamp art is rebuilt from gradient layers and elliptical-corner paths (no asset), the flame drops the prototype's `brightness` filter, and a few font sizes use the nearest `ILTypography` preset (garden kind chip 10.5 vs 10). Layout was built from the CSS and not run on a device.
VI: Hình đèn dựng lại bằng gradient layer và path bo góc elip (không có asset), ngọn lửa bỏ filter `brightness` của prototype, vài cỡ chữ dùng preset `ILTypography` gần nhất (chip loại đèn 10.5 so với 10). Bố cục dựng theo CSS và chưa chạy trên thiết bị.

## Why it was taken on / Lý do chấp nhận nợ
EN: AGENTS.md forbids running the simulator; the user verifies UI on a physical device.
VI: AGENTS.md cấm chạy simulator; người dùng tự kiểm tra UI trên thiết bị thật.

## Impact / Ảnh hưởng
EN: Small visual differences from the design (proportions, glow strength, animation feel) are possible.
VI: Có thể có sai khác nhỏ so với thiết kế (tỉ lệ, độ sáng quầng, cảm giác chuyển động).

## Proposed fix / Hướng xử lý
EN: QA on device against the prototype; replace the code-drawn lamps with exported assets if Design provides them.
VI: QA trên thiết bị đối chiếu prototype; thay hình đèn vẽ bằng code bằng asset nếu Design cung cấp.

## Resolution / Kết quả xử lý
EN: _(fill in when Resolved: date, commit/PR)_
VI: _(điền khi Resolved: ngày, commit/PR)_
