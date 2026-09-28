# Temple

## Overview

Temple detail screen ("Trang chùa") — a full temple profile: a transparent hero (2 chips for
cấp di tích/hệ phái, name, "Còn gọi: …" alias line, place line) whose header band turns solid and
shows the temple name once scrolled past; 3 pill buttons (Theo dõi / Chỉ đường / Cúng dường)
overlapping the hero; a status card (open/closed + distance + weekday/holiday hours); a 4-tile
facts grid (Niên đại · Cấp di tích · Hệ phái · Vùng miền); a collapsible "Giới thiệu" biography;
"Tổ chức & truyền thừa" (Trụ trì/Tổ khai sơn/Giáo hội, each falling back to "Đang cập nhật");
"Kiến trúc & di sản" (style + materials + highlight cards); a 5-tile "Tiện ích" amenities grid;
a highlighted "Lưu ý khi viếng thăm" numbered-rules card; "Sự kiện & khóa học" (session list or a
dashed empty state); and "Vị trí & liên hệ" (map placeholder, address, Google/Apple Maps buttons,
Hotline/Fanpage/Website/Email contact rows) with a footer.

Reached from the Home "Chùa Việt Nam" carousel (`ILHomeCoordinator`) and the Sangha community card
(`ILSanghaCoordinator`) — both pass a `templeID`. Design: prototype screen `temple`
(`Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, `Component.TEMPLE_INFO`).
Spec: `Docs/Specs/Temple/` (`requirements.md`/`design.md`/`tasks.md`, v2.0).

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILTempleEntity.swift` | Done | Full catalog shape (identity/location, sect + org info, era/rank/architecture/highlights/bio, opening hours, contacts, amenities, visit rules, sessions). Pure business fields — no formatted strings, no "now"-derived state. |
| Presentation — StateModel | `ILTempleStateModel.swift` | Done | All display-ready strings/flags (chip text, status/hours, facts, org/amenity/contact rows with fallback text, numbered rules, formatted address/coord). |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | No temple endpoint confirmed. |
| Domain — UseCase | `ILTempleUseCase.swift` | Skeleton | `getInitialState` returns a static 9-temple catalog (Từ Quang fully detailed + the 8-temple Home carousel set); `toggleFollow` is a TODO stub (needs repository). |
| Presentation — ViewModel | `ILTempleViewModel.swift` | Done | 10 Inputs; computes open/closed + distance client-side (`ILLunarCalendar` + haversine, fixed user location); optimistic local follow/bio-expanded state; builds Maps/tel/mailto URLs for `.openURL`. |
| Presentation — ViewController | `ILTempleViewController.swift` | Done | Header-solid-on-scroll (`ILDeityViewController` pattern), collapsible biography, 2-column grid helper, leaf row/tile views defined in-file (fact tile, amenity tile, key-value row, highlight card, rule row). |
| Presentation — Coordinator | `ILTempleCoordinator.swift` | Partial | `.back` pops + finishes; `.openURL` opens the system app (Maps/tel/https/mailto); `.offer` / `.events` / `.session` are TODO (target screens not built). |
| Feature-scoped views | `Views/ILTempleHeroView.swift`, `Views/ILTempleStatusCardView.swift` | Done | Hero (chips/name/alias/place) and the open-status + hours card. |
| Tests | `ILTempleViewModelTests.swift` | Done | 11 tests — state mapping (incl. injected clock for deterministic open/closed) + one per Input. |
| Wiring | `DIContainer` + `ILHomeCoordinator` + `ILSanghaCoordinator` | Done | Home carousel + Sangha community card open this screen. |

## Navigation events

- `back` — header ‹ tapped. Pops the screen and finishes the coordinator.
- `offer` — "Cúng dường" tapped. TODO (offer screen not built).
- `events` — "Xem tất cả" / empty-state tap in "Sự kiện & khóa học". TODO (events screen not built).
- `session(id:)` — an upcoming session tapped. TODO (session detail / reader not built).
- `openURL(String)` — "Chỉ đường"/Google Maps/Apple Maps buttons and a contact row with a value
  (Hotline → `tel:`, Fanpage/Website → `https://`, Email → `mailto:`). The Coordinator calls
  `UIApplication.shared.open(_:)`; the ViewModel only builds the URL string, so it stays testable.

## Known gaps / not implemented yet

- All data is mock (`ILTempleUseCaseImpl.makeTempleCatalog()`): 9 temples transcribed from the
  design handoff's `Component.TEMPLE_INFO` (Từ Quang fully detailed; the other 8 reuse
  `home.temple.*` name/place keys, matching the Home carousel).
- `toggleFollow` is a stub — the "Theo dõi"/"Đang theo dõi" label toggles optimistically in the
  ViewModel, but nothing persists across app launches (needs a followed-temples repository).
- "Cúng dường", "Xem tất cả" (events) and session taps are TODO (their screens are unbuilt).
- Distance uses a fixed user location (Quận 1, TP.HCM) — no location permission flow yet.
- Loading / error / offline states not rendered (`.failure` is a fallback branch).
- "Báo thông tin sai" in the footer has no action wired (the design prototype doesn't define one
  either).

## Changelog

- 2026-09-28 — redesigned to match the full design handoff (`isTemple` in
  `InnerLamp Prototype.dc.html`): rebuilt `ILTempleEntity`/`ILTempleUseCase` around the full
  `TEMPLE_INFO` catalog shape (9 temples), rebuilt `ILTempleStateModel`/`ILTempleViewModel`
  (header-solid-on-scroll, collapsible bio, status card, facts/amenities grids, org info,
  architecture highlights, visit rules, location & contacts, `.openURL` nav event), rewrote
  `ILTempleHeroView`, added `ILTempleStatusCardView`, removed `ILTempleStatsView` (superseded by
  the status card + facts grid). Visual QA passed against the design on both a fully-detailed
  temple (Từ Quang) and a mostly-empty one (Một Cột).
- 2026-09-26 — initial implementation from design handoff prototype screen `temple`
  (il-screen-builder). Added themed tokens `ILColors.templeHeaderTop/Mid/Ink/Glow` (+ assets) and
  `ILTypography.statValueMedium`; wired Home carousel and Sangha community card to this screen.
