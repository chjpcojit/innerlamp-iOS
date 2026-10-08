# Tasks — Temple

Version: 2.4
Last updated: 2026-09-30
Status: in-progress (Phase 1–2 done; Phase 3 detail API wired, follow + manual test pending; list/discovery is a separate feature)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this spec covers the implemented **detail screen**. The discovery/list
> feature in `SRS.md` (`FR-001`–`FR-012`) is a separate, unbuilt feature.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILTempleViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: transparent hero + header-solid-on-scroll,
      3 pill buttons, status card, facts grid, collapsible biography, org info card,
      architecture + highlights, amenities grid, visit-rules card, events list/empty
      state, location + contacts cards, footer — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILTempleHeroView`, `ILTempleStatusCardView`
      (`ILTempleStatsView` removed — superseded by the status card + facts grid)
- [x] Add `ILColors.templeHeaderTop/Mid/Ink/Glow` + `ILTypography.statValueMedium`
      (v1); reused existing tokens for v2 (no new color assets needed)
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `temple`) — checked
      on both a fully-detailed temple (Từ Quang) and a mostly-empty one (Một Cột)
      in the Simulator

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILTempleEntity` + `ILTempleSessionEntity` + tone/glyph enums
      (v2: expanded to the full `TEMPLE_INFO` shape — aliases, org info, era/rank/
      archStyle/materials/highlights/bio, opening hours ×2, contacts, amenities,
      visit rules)
- [x] Create `ILTempleStateModel` + `ILTempleSessionModel` (v2: added hour-row,
      fact, org-info, amenity, contact, and rule row models)
- [x] Create `ILTempleUseCase` / `ILTempleUseCaseImpl` (catalog, toggleFollow stub)
      (v2: 9-temple catalog transcribed from `Component.TEMPLE_INFO`)
- [x] Create `ILTempleViewModel` (`Input -> Output`, `ILTempleNavEvent`,
      `templeID` parameter) (v2: added `bioToggled`, `googleMapsTapped`,
      `appleMapsTapped`, `eventsTapped`, `contactTapped` inputs; open/closed +
      distance computed client-side via `ILLunarCalendar` + haversine; injectable
      `now:` clock)
- [x] Create `ILTempleCoordinator` (leaf — `.back` pop+finish; `.openURL` opens
      the system app; `.offer`/`.events`/`.session` TODO)
- [x] Wire `DIContainer.makeTempleUseCase/ViewModel/Coordinator`
- [x] Wire `ILHomeCoordinator.showTemple(id)` + `ILSanghaCoordinator.showTemple(id)`
- [x] Unit tests: `InnerLampTests/ILTempleViewModelTests.swift` (11 tests) —
      per-Input, full state mapping with an injected fixed clock, Maps/contact
      URL building

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the temple list/detail API contract(s) — `SRS.md` proposes
> `GET /v1/temples`, `/top`, `/{id}`, none in `Docs/Specs/API/openapi.yaml` v3.9.
> Everything below is blocked until a contract exists.

- [x] Define the temple API contract(s) with the backend team (list, top, detail)
      — confirmed by BE-Developer 2026-09-29 (backend `docs/specs/features/temple/api-contract.md`)
- [x] Create `ILTempleDTO` + `ILTempleMapper` (once confirmed)
- [x] Create `TempleEndpoint`(s) under `Data/DataSources/Remote/`
- [x] Create `ILTempleRepository` protocol + implementation wrapping
      `NetworkService` (+ Core Data cache, see changelog v2.1)
- [x] Replace the static catalog in `ILTempleUseCaseImpl` with real data
      (`loadTemple(id:)` → `ILTempleRepository.loadTempleDetail(id:)`, see changelog v2.2)
- [ ] Implement `toggleFollow` with a followed-temples repository
- [x] Add loading / error / offline states (full-screen loading dots; `ILStateView`
      error/offline + "Thử lại" retry)
- [x] Update `ILTempleViewModelTests` + add a mock repository (`ILTempleUseCaseTests`)
      — ⚠️ not run yet: the test target currently fails to compile on unrelated
      `InnerLampTests/GRPC/*` module-resolution errors
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Sub-destinations (pending, separate scope)

- [x] Wire Google Maps / Apple Maps / Hotline / Fanpage / Website / Email to the
      system apps via `.openURL` + `UIApplication.shared.open(_:)`
- [ ] Build the Offer screen and wire `.offer`
- [ ] Build the "Sự kiện & khóa học của chùa này" screen and wire `.events`
- [ ] Build the session-detail / reader screen and wire `.session(id:)`
- [ ] Fill biography / architecture / visit rules / contacts / holiday hours / "Giáo hội" /
      "Kinh sách" / events once the temple API supplies them (UI already in place, currently
      "Đang cập nhật")
- [ ] Update `InnerLamp/Presentation/Scenes/Temple/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Temple/README.md` (implementation notes,
      status table, changelog)
- [x] `Docs/Specs/Temple/SRS.md` (upstream BA requirements — kept as-is)
- [x] `Docs/Knowledge/features/temple.md` (OKF concept) — updated alongside the
      v2 redesign; still `status: draft` (mock catalog, no API yet). See
      `Docs/Specs/OKF.md`.

## Deferred (separate feature — the discovery/list scope from SRS.md)

- Temple list / discovery screen (top temples + paginated directory + filters +
  search + infinite scroll) — `SRS.md` `FR-001`–`FR-012`. Not implemented; a
  separate feature with its own spec when built.
