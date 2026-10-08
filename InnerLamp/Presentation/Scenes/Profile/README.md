# Profile

## Overview

Me tab ("Tôi", prototype screen `profile`): pinned header (avatar, name, "Pháp danh … · Phật tử tại
gia", "Sửa hồ sơ" pill), a 3-cell practice stats card (hours / streak / chant count), the
"Nhật ký 12 tuần qua" heatmap card, the "Dấu ấn tu tập" recent-badges row, the dark "Công đức đã hồi
hướng" merit card, the "Sen Vàng" upgrade card (free plan only), and a 4-row menu (reminder,
settings, notifications, my sangha).
Tab 4 of `ILMainTabBarController` (owned by `ILMainTabCoordinator`; switching tabs is handled by
the tab bar, not by this screen). Design: prototype screen `profile`
(`Docs/design_handoff_innerlamp/`). No spec under `Docs/Specs/Profile/` yet.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILProfileEntity.swift` | Done | Name, dharma name, practice stats, journal entries/day, recent badges, offering counts, plan, reminder, community. Pure business fields (no formatted strings). |
| Presentation — StateModel | `ILProfileStateModel.swift` | Done | Formatted stats / summaries, heatmap alphas, badge models, `showsPremiumUpsell`, menu values. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | No profile / stats / badges endpoint confirmed. |
| Domain — UseCase | `ILProfileUseCase.swift` | Skeleton | `getProfile()` returns a static mock (TODO: `ILProfileRepository` → `ILUserRepository` + network). |
| Presentation — ViewModel | `ILProfileViewModel.swift` | Done | 10 Inputs, Entity → StateModel mapping, compact-count / reminder / heatmap-alpha / initial formatting. |
| Presentation — ViewController | `ILProfileViewController.swift` | Done | Built from `ILStatSummaryCardView`, `ILHeatmapGridView` (new, shared), `ILSectionHeaderView`, `ILSettingRow`, `ILFlameView` + `Views/`. Visual QA pending. |
| Presentation — Coordinator | `ILProfileCoordinator.swift` | Partial | `openSettings`, `openNotifications`, `editProfile` push their screens; the rest are TODO (target screens not built). |
| Tests | `ILProfileViewModelTests.swift` | Done | 1 test per Input + state mapping (full / empty / paid plan) + formatting helpers. |
| Wiring | `DIContainer` + `ILMainTabCoordinator` | Done | Replaces the Me tab's `ILTabPlaceholderViewController`. |

## Navigation events

- `editProfile` — "Sửa hồ sơ" pill tapped. Pushes `ILEditProfileCoordinator`.
- `openStats` — heatmap card tapped. TODO (`stats` not built).
- `openAwards` — "Xem cả N dấu ấn" link or badges row tapped. TODO (`awards` not built).
- `openOffering` — merit card tapped. TODO (`offer` not built).
- `openPaywall` — Sen Vàng card tapped. TODO (`paywall` modal not built).
- `openReminder` — "Chuông tỉnh thức" row tapped. TODO (`remind` not built).
- `openSettings` — "Cài đặt" row tapped. Pushed to `ILSettingsCoordinator`.
- `openNotifications` — "Thông báo" row tapped. Pushed to `ILNotificationsCoordinator`.
- `openFamilyTree` — "Gia phả" row tapped. Pushed to `ILFamilyTreeCoordinator` (`Scenes/FamilyTree/`).
- `openCommunity(id:)` — "Đạo tràng của tôi" row tapped (only when the user has a community). TODO (`temple` not built).

## Known gaps / not implemented yet

- All data is mock (`ILProfileUseCaseImpl.getProfile()`) — profile, stats, heatmap, badges, merit and plan
  need API contracts. `ILUserRepository` (local Core Data) already stores phone / dharma name / email
  but has no full name, so it can't back this screen alone.
- Avatar shows the initial only — no photo. Its gradient is `canvasWarmEnd1 → tint` (prototype uses `--il-sunk2 → --il-tint`, no matching token).
- Header subtitle role "Phật tử tại gia" is fixed copy — the account has no role field yet.
- "Đạo tràng của tôi" row is inert when the user has no community (shows "Chưa tham gia") — there is no "find a sangha" event wired from here yet.
- Sen Vàng trial copy ("Dùng thử 7 ngày miễn phí") is static; it should follow plan / trial eligibility once the paywall exists.
- Loading / error / offline states not rendered (`.failure` is a TODO branch).
- `ILTabPlaceholderViewController` (`Scenes/Main/`) is now unused by any tab and can be deleted.
- Lamp (centre bar button) tab still unbuilt.

## Changelog

- 2026-09-20 — initial implementation from design handoff prototype screen `profile` (il-screen-builder). Added shared `ILStatSummaryCardView`, `ILHeatmapGridView`, `ILTypography.statValue/microCaption`.
- 2026-09-27 — `editProfile` now opens the new Edit Profile screen (il-screen-builder, `EditProfile`).
- 2026-10-03 — added the "Gia phả" menu row (`openFamilyTree`).
