# Temple

## Overview

Temple detail screen ("Trang chùa") — a full temple profile: a transparent hero (2 chips for
cấp di tích/hệ phái, name, "Còn gọi: …" alias line, place line) whose header band turns solid and
shows the temple name once scrolled past; 3 pill buttons (Theo dõi / Chỉ đường / Cúng dường)
overlapping the hero; a status card (open/closed + distance + weekday/holiday hours); a 4-tile
facts grid (Niên đại · Cấp di tích · Hệ phái · Vùng miền); a collapsible "Giới thiệu" biography;
"Tổ chức & truyền thừa" (Trụ trì/Tổ khai sơn/Giáo hội); "Kiến trúc & di sản" (paragraph +
highlight cards); a 5-tile "Tiện ích" amenities grid; a highlighted "Lưu ý khi viếng thăm" card;
"Sự kiện & khóa học" (session list or a dashed empty state); and "Vị trí & liên hệ" (map
placeholder, address, Google/Apple Maps buttons, Hotline/Fanpage/Website/Email rows) with a footer.

**Data rule:** content comes only from `GET /v1/temples/{id}`. Every section is always shown; a
field the API does not send is left unfilled and rendered as "Đang cập nhật" (events: empty state;
distance: blank). While loading the whole screen shows `ILTempleSkeletonView` (pulsing skeleton); on failure an `ILStateView`
(error / offline) with "Thử lại".

Reached from the Home "Chùa Việt Nam" carousel (`ILHomeCoordinator`) and the Chùa tab
(`ILSanghaCoordinator`) — both pass a `templeID`. Design: prototype screen `temple`
(`Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, `Component.TEMPLE_INFO`).
Spec: `Docs/Specs/Temple/` (see `changelog.md` v2.5).

## What the API fills

| Section | From the API | Placeholder ("Đang cập nhật") |
|---|---|---|
| Hero | name, aliases, heritage rank, sect, address | — |
| Status card | `operating_hours` → "Ngày thường" row + open/closed | "Rằm & Mùng Một" row; distance blank |
| Facts grid | founding year, rank, sect, region | year when `0` |
| Org info | current abbot, founder (when non-empty) | "Giáo hội" |
| Amenities | car, motorbike, vegetarian meals, summer retreat | "Kinh sách" |
| Location | address, region, coordinates, Maps buttons | 4 contact rows |
| Giới thiệu | `introduction` | whole section when `""` |
| Kiến trúc & di sản | `architecture_heritage` (one paragraph) | paragraph when `""`; highlight cards always empty |
| Lưu ý khi viếng thăm | `visiting_notes`, numbered 01, 02… | whole card when `[]` |
| Events | — | empty state |
| Footer | — | "Cập nhật …" hidden, "Báo thông tin sai" shown |

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `Domain/Entities/ILTempleCatalogEntity.swift` (`ILTempleDetailEntity`) | Done | Server temple profile. |
| Data — DTO + Mapper + Repository | `ILTempleDTO`, `ILTempleMapper`, `TempleDetailEndpoint`, `ILTempleRepositoryImpl` | Done | Network-first with Core Data fallback; errors are `ILCatalogError`. |
| Domain — UseCase | `ILTempleUseCase.swift` | Partial | `loadTemple(id:)` → repository; `toggleFollow` is still a TODO stub. |
| Presentation — StateModel | `ILTempleStateModel.swift` | Done | Full design shape; fields without API data stay empty. |
| Presentation — ViewModel | `ILTempleViewModel.swift` | Done | Load / retry, API → state mapping, open/closed from `operating_hours`, optimistic follow + revert, Maps/contact URLs. |
| Presentation — ViewController | `ILTempleViewController.swift` | Done | All sections always shown; "Đang cập nhật" placeholder for empty text sections; loading / error+retry. |
| Presentation — Coordinator | `ILTempleCoordinator.swift` | Partial | `.back`, `.openURL` done; `.offer` / `.events` / `.session` TODO. |
| Feature-scoped views | `Views/ILTempleHeroView.swift`, `Views/ILTempleStatusCardView.swift` | Done | |
| Tests | `ILTempleViewModelTests.swift`, `ILTempleUseCaseTests.swift` | Written, not run | Blocked by unrelated GRPC test compile errors. |
| Wiring | `DIContainer` + `ILHomeCoordinator` + `ILSanghaCoordinator` | Done | |

## Navigation events

- `back` — header ‹ tapped. Pops the screen and finishes the coordinator.
- `offer` — "Cúng dường" tapped. TODO (offer screen not built).
- `events` — "Xem tất cả" / empty-state tap in "Sự kiện & khóa học". TODO (events screen not built).
- `session(id:)` — an upcoming session tapped. TODO (session detail / reader not built).
- `openURL(String)` — "Chỉ đường"/Google Maps/Apple Maps buttons and a contact row with a value
  (Hotline → `tel:`, Fanpage/Website → `https://`, Email → `mailto:`).

## Known gaps / not implemented yet

- Sections marked "Đang cập nhật" above wait for the API to add those fields.
- Distance needs real location permission.
- The Sangha community card passes mock ids, not server temple ids → "not found" error state.
- `toggleFollow` is a stub — nothing persists.
- "Báo thông tin sai" has no action wired.

## Changelog

- 2026-09-30 — introduction / architecture & heritage / visiting notes filled from API contract
  v1.1. Details: `Docs/Specs/Temple/changelog.md` v2.5.
- 2026-09-30 — full UI restored (v2.3 had removed non-API sections); only API data is filled,
  everything else shows "Đang cập nhật". Details: `Docs/Specs/Temple/changelog.md` v2.4.
- 2026-09-30 — wired to `GET /v1/temples/{id}` with loading / error / retry; mock catalog +
  `ILTempleEntity` removed (v2.2).
- 2026-09-28 — redesigned to match the full design handoff with a static 9-temple catalog.
- 2026-09-26 — initial implementation from design handoff prototype screen `temple`
  (il-screen-builder).
