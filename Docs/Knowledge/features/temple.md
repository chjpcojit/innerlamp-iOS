---
type: Feature
title: Temple
description: Temple detail screen ("Trang chùa") — full profile (hero, open/closed status, hours, facts, biography, organization, architecture, amenities, visit rules, upcoming sessions, location & contacts) from a static 9-temple mock catalog; the SRS's list/discovery scope is not yet implemented.
resource: InnerLamp/Presentation/Scenes/Temple/
tags: [discovery, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-28T12:35:00+07:00 }
sources:
  - path: Docs/Specs/Temple/design.md
    kind: spec
  - path: InnerLamp/Domain/Entities/ILTempleEntity.swift
    kind: code
  - path: InnerLamp/Domain/UseCases/Temple/ILTempleUseCase.swift
    kind: code
  - path: InnerLamp/Presentation/Scenes/Temple/ILTempleViewModel.swift
    kind: code
  - path: InnerLamp/Presentation/Scenes/Temple/ILTempleCoordinator.swift
    kind: code
---

# Summary

Temple is a leaf detail screen ("Trang chùa") reached from the Home temple
carousel and the Sangha community card (`showTemple(id)`). It shows a full
temple profile: a hero (cấp-di-tích/hệ-phái chips, name, alias line, place),
3 action buttons (Theo dõi / Chỉ đường / Cúng dường), an open/closed status
card with weekday and Rằm/Mùng-Một hours, a 4-tile facts grid, a collapsible
biography, "Tổ chức & truyền thừa" (abbot/founder/sangha), "Kiến trúc & di
sản" (style/materials/highlights), a 5-tile amenities grid, a numbered
visit-rules card, an upcoming-sessions list (or a dashed empty state), and
"Vị trí & liên hệ" (map placeholder, address, Maps buttons, contact rows).
The data comes from a static 9-temple mock catalog in `ILTempleUseCaseImpl`,
transcribed from the design handoff's `Component.TEMPLE_INFO`; `getInitialState`
falls back to the fully-detailed "Từ Quang" temple when an id is not found.

Open/closed status and distance are **not** part of the mock data — they are
computed client-side in `ILTempleViewModel` from the current time
(`ILLunarCalendar.solarToLunar` decides whether today's Rằm/Mùng-Một hours
apply) and a haversine formula against a fixed reference location (Quận 1,
TP.HCM — no location permission flow exists yet).

The `Docs/Specs/Temple/SRS.md` describes a **much larger feature** (a curated
"top temples" list, a paginated directory with infinite scroll, type/region
filters, name search, image loading, cross-feature entry from Sangha/Profile) —
that scope is still a draft SRS with no engineering spec beyond
`Docs/Specs/Temple/requirements.md`/`design.md`/`tasks.md` (which cover only
the detail screen), and is **not implemented**. This concept documents only the
shipped detail screen.

**Current limitation**: the catalog is mock data and `toggleFollow` is a stub —
see [Pending work](#pending-work).

# Architecture

MVVM-C + Clean Architecture. `ILTempleCoordinator` is a leaf (no delegate),
created by `ILHomeCoordinator`/`ILSanghaCoordinator` and pushed onto the
current tab's stack.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILTempleEntity.swift` — identity/location, `sect` + `ILTempleOrgInfoEntity[]`, era/`rank?`/archStyle/materials/highlights/bio, `ILTempleOpeningHoursEntity` ×2, `ILTempleContactEntity[]`, `ILTempleAmenityEntity[]`, visitRules, hasUpcomingSchedule, `sessions`, updatedLabel; plus `ILTempleSessionEntity`, `ILTempleSessionTone`, `ILTempleSessionGlyph` |
| Domain / UseCase | UseCase | `Domain/UseCases/Temple/ILTempleUseCase.swift` — `getInitialState(templeID:)` (9-temple mock catalog, fallback to Từ Quang), `toggleFollow(templeID:)` **stub** |
| Presentation / State | State Model | `Presentation/Scenes/Temple/ILTempleStateModel.swift` — UI-only pre-formatted strings/flags for every section |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Temple/ILTempleViewModel.swift` — `Input -> Output`; client-side open/closed + distance computation; `applyEntity(_:)` / `publishState()` |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Temple/ILTempleCoordinator.swift` — leaf; `.back` → pop + finish; `.openURL` → `UIApplication.shared.open(_:)`; `.offer` / `.events` / `.session` → TODO |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Temple/ILTempleViewController.swift` |
| Feature-scoped views | View | `Presentation/Scenes/Temple/Views/ILTempleHeroView.swift`, `ILTempleStatusCardView.swift` |
| Tests | Unit tests | `InnerLampTests/ILTempleViewModelTests.swift` |

The catalog reuses `home.temple.*` localization keys for `name`/place text (the
same data source as Home's carousel and `ILFestivalsUseCase`); all other
catalog content (bio, org info, hours, contacts, amenities, rules) is plain
Vietnamese string literals in `ILTempleUseCaseImpl` — data, not UI copy, same
convention as `ILDeityUseCaseImpl`.

# Navigation

```
ILHomeCoordinator (Home tab) / ILSanghaCoordinator
  └─ showTemple(id) → ILTempleCoordinator                 (leaf, no delegate)
       push ILTempleViewController
       (.back) → pop + finish
       (.openURL(url)) → UIApplication.shared.open(url)   [Maps / tel / https / mailto]
       (.offer / .events / .session) → TODO (not built)
```

# Pending work

- The catalog is mock data (`ILTempleUseCaseImpl.makeTempleCatalog()`), marked
  `// TODO: … networkService` for a real temples API.
- `toggleFollow(templeID:)` is a `print("TODO: …")` stub — the follow button
  label toggles optimistically in the ViewModel but nothing persists.
- The `.offer`, `.events`, and `.session(id:)` destinations are TODO — their
  target screens are not built.
- Distance uses a fixed reference location; no location-permission flow yet.
- The SRS's list/discovery scope (top temples, paginated directory, filters,
  search, image caching, cross-feature entry) is unimplemented and blocked on
  open questions (endpoint paths, `type` enum values, region taxonomy, cover vs
  gallery, pagination mechanics).
- Promote to `stable` once a real temples API and the discovery scope land and
  are exercised end-to-end.

# Known gaps vs. design

- The SRS (`Docs/Specs/Temple/SRS.md`, v0.1) is a draft awaiting confirmation and
  has no downstream requirements/design/tasks beyond what covers the detail
  screen. The shipped code implements only the detail screen, not the
  list/discovery flow the SRS anticipates.

# Related concepts

- [Home](home.md) (`InnerLamp/Presentation/Scenes/Home/`) — reached via the
  temple carousel; shares the `home.temple.*` catalog and localization keys.
- Sangha / Profile (`InnerLamp/Presentation/Scenes/Sangha/`,
  `Presentation/Scenes/Profile/`) — the SRS's intended cross-feature entry points
  (`openFindSangha`, `openCommunity(id:)`); still TODO, no OKF concepts.
