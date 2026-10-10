# Profile

## Overview

Me tab ("Tôi", prototype screen `profile`): a 250pt cover (parallax / stretch) with the "Sửa hồ sơ"
pill on it, an 84pt avatar overlapping the cover beside the name and "Pháp danh … · Phật tử tại gia",
a pinned compact name bar that fades in on scroll, a 3-cell practice stats card (hours / streak /
chant count), the "Nhật ký 12 tuần qua" heatmap card, the "Dấu ấn tu tập" recent-badges row, the
dark "Công đức đã hồi hướng" merit card, the always-visible "Ủng hộ InnerLamp" card, a 7-row icon
menu (family tree, create family tree, reminder, merit book, settings, notifications, my temple) and
a version / build footer read from the bundle.
Tab 4 of `ILMainTabBarController` (owned by `ILMainTabCoordinator`; switching tabs is handled by
the tab bar, not by this screen). Design: prototype screen `profile`
(`Docs/innerlamp-project/project/InnerLamp Prototype.dc.html`, `isProfile`). Spec: `Docs/Specs/Profile/`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILProfileEntity.swift` | Done | Name, dharma name, practice stats, journal entries/day, recent badges, offering counts, plan, reminder, community. Pure business fields (no formatted strings). |
| Presentation — StateModel | `ILProfileStateModel.swift` | Done | Formatted stats / summaries, heatmap alphas, badge models, menu values, `versionText` / `buildText`. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | No profile / stats / badges endpoint confirmed. |
| Domain — UseCase | `ILProfileUseCase.swift` | Skeleton | `getProfile()` returns a static mock (TODO: `ILProfileRepository` → `ILUserRepository` + network). |
| Presentation — ViewModel | `ILProfileViewModel.swift` | Done | 12 Inputs (11 taps + viewDidLoad), injected `Bundle` for version text, Entity → StateModel mapping, compact-count / reminder / heatmap-alpha / initial formatting. |
| Presentation — ViewController | `ILProfileViewController.swift` | Done | Built from `ILStatSummaryCardView`, `ILHeatmapGridView` (shared), `ILSectionHeaderView`, `ILSettingRow` (now with optional icon), `ILFlameView` + `Views/` (`ILProfileHeaderView` cover + scroll maths, `ILProfileCompactBarView`, `ILProfileDonateCardView`, `ILProfileVersionFooterView`). Visual QA pending. |
| Presentation — Coordinator | `ILProfileCoordinator.swift` | Partial | `editProfile`, `openStats`, `openSettings`, `openNotifications`, `openFamilyTree`, `createFamilyTree` push their screens; `openAwards`, `openOffering`, `openDonate`, `openReminder`, `openMeritBook`, `openCommunity` are TODO (target screens not built). |
| Tests | `ILProfileViewModelTests.swift` | Done | 1 test per Input + state mapping (full / empty / paid plan) + formatting helpers. |
| Wiring | `DIContainer` + `ILMainTabCoordinator` | Done | Replaces the Me tab's `ILTabPlaceholderViewController`. |

## Navigation events

- `editProfile` — "Sửa hồ sơ" pill tapped. Pushes `ILEditProfileCoordinator`.
- `openStats` — heatmap card tapped. TODO (`stats` not built).
- `openAwards` — "Xem cả N dấu ấn" link or badges row tapped. TODO (`awards` not built).
- `openOffering` — merit card tapped. TODO (`offer` not built).
- `openDonate` — "Ủng hộ InnerLamp" card tapped (was `openPaywall`). TODO (`paywall` / donate screen not built).
- `openMeritBook` — "Sổ công đức" row tapped. TODO (merit book not built).
- `createFamilyTree` — "Tạo gia phả mới" row tapped. Pushed to `ILFamilyTreeCreateCoordinator`.
- `openReminder` — "Chuông tỉnh thức" row tapped. TODO (`remind` not built).
- `openSettings` — "Cài đặt" row tapped. Pushed to `ILSettingsCoordinator`.
- `openNotifications` — "Thông báo" row tapped. Pushed to `ILNotificationsCoordinator`.
- `openFamilyTree` — "Gia phả dòng họ" row tapped. Pushed to `ILFamilyTreeCoordinator` (`Scenes/FamilyTree/`).
- `openCommunity(id:)` — "Chùa tu tập" row tapped (only when the user has a community). TODO (`temple` not built).

## Known gaps / not implemented yet

- All data is mock (`ILProfileUseCaseImpl.getProfile()`) — profile, stats, heatmap, badges, merit and plan
  need API contracts. `ILUserRepository` (local Core Data) already stores phone / dharma name / email
  but has no full name, so it can't back this screen alone.
- Avatar shows the initial only — no photo. Its gradient is `canvasWarmEnd1 → tint` (prototype uses `--il-sunk2 → --il-tint`, no matching token).
- Header subtitle role "Phật tử tại gia" is fixed copy — the account has no role field yet.
- "Chùa tu tập" row is inert when the user has no community (shows "Chưa tham gia") — there is no "find a sangha" event wired from here yet.
- Cover is a gradient placeholder — the default photo asset is missing (`Docs/Tech-Debt/Profile/TD-Profile-001-*`); per-user cover source unconfirmed (`Docs/Assumptions/Profile/AS-Profile-001-*`).
- "Gia phả dòng họ" row has no trailing family-tree name (no data source on this screen).
- The merit card still draws its flame in a ring; the prototype now uses the `lamp` icon at 44pt (not changed in this pass).
- Loading / error / offline states not rendered (`.failure` is a TODO branch).
- `ILTabPlaceholderViewController` (`Scenes/Main/`) is now unused by any tab and can be deleted.
- Lamp (centre bar button) tab still unbuilt.

## Changelog

- 2026-09-20 — initial implementation from design handoff prototype screen `profile` (ui-builder). Added shared `ILStatSummaryCardView`, `ILHeatmapGridView`, `ILTypography.statValue/microCaption`.
- 2026-09-27 — `editProfile` now opens the new Edit Profile screen (ui-builder, `EditProfile`).
- 2026-10-03 — added the "Gia phả" menu row (`openFamilyTree`).
- 2026-10-10 — redesign to the new prototype `profile`: cover with parallax/stretch + compact bar, "Ủng hộ InnerLamp" card replaces Sen Vàng (always shown), 7-row icon menu (adds create family tree, merit book), bundle version footer; `ILSettingRow` gains an optional icon, 8 new row icons (ui-builder).
