---
id: AS-LightLamp-004
title: My lamps are labelled "Của bạn" instead of the user's name
title_vi: Đèn của tôi gắn nhãn "Của bạn" thay vì tên người dùng
feature: LightLamp
level: Low
status: Unvalidated
created: 2026-10-11
updated: 2026-10-11
files:
  - InnerLamp/Presentation/Scenes/LightLamp/ILLampGardenViewModel.swift:122
  - InnerLamp/Resources/Localization/vi.json
source: Docs/Specs/LightLamp/requirements.md (Pending — owner name on lamps, ⚠️ Not confirmed)
owner: Product / BA
---

## Assumption / Giả định
EN: The garden card title is "Của bạn · <intention>" ("Yours"). No owner name is stored on the lamp because the app has no real display-name source yet (see TD-Home-002).
VI: Tiêu đề thẻ ở vườn đèn là "Của bạn · <tâm nguyện>". Đèn không lưu tên chủ vì app chưa có nguồn tên hiển thị thật (xem TD-Home-002).

## Rationale / Cơ sở giả định
EN: The prototype hardcodes "Tâm Minh"; hardcoding a fake name would be wrong for every real user.
VI: Prototype cứng tên "Tâm Minh"; cứng một tên giả sẽ sai với mọi người dùng thật.

## Implications if wrong / Hệ quả nếu sai
EN: Once a name source exists, lamps lit before that have no name; the label or the model needs a follow-up change.
VI: Khi có nguồn tên, đèn thắp trước đó không có tên; cần đổi nhãn hoặc model.

## Validation / Cách xác nhận
EN: Revisit after the profile/display-name source lands (TD-Home-002); decide whether lamps store the name at lighting time.
VI: Xem lại sau khi có nguồn tên hiển thị (TD-Home-002); quyết định có lưu tên lúc thắp hay không.

## Outcome / Kết luận
EN: _(fill in when Validated/Invalidated: decision, date, who confirmed)_
VI: _(điền khi Validated/Invalidated: quyết định, ngày, người xác nhận)_
