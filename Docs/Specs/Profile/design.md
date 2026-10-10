# Design — Profile

Version: 1.1
Last updated: 2026-10-10
Status: in-progress — v1.1 redesign specced (code pending); mock data; destinations
partially built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Profile ("Tôi") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
**tab 4** of `ILMainTabBarController`, so `ILProfileCoordinator` is owned by
`ILMainTabCoordinator` (which gives it its own `BaseNavigationController`).
There is **no network** — the UseCase returns static mock data.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILProfileEntity.swift` | `ILProfileEntity` (name, dharmaName, practiceStats, journalEntriesPerDay, recentBadges, totalBadgeCount, offeringCount, lanternCount, plan, reminder, community) + sub-entities/enums (`ILProfilePlan`, `ILProfilePracticeStatsEntity`, `ILProfileBadgeCategory`, `ILProfileBadgeEntity`, `ILProfileReminderEntity`, `ILProfileCommunityEntity`). No UI-only state. Unchanged in v1.1 (`plan` stays; the screen just no longer branches on it). |
| Domain / UseCase | `Domain/UseCases/Profile/ILProfileUseCase.swift` | `getProfile()` — static mock (TODO: repository → network). |
| Presentation / State | `Presentation/Scenes/Profile/ILProfileStateModel.swift` | UI-only state: header, stat models, heatmap (intensities), badge models, merit summary, menu values (reminder, community; the family-tree row value is not modelled until its source is confirmed), **`versionText` / `buildText`** ("InnerLamp · Phiên bản x" / "Bản dựng y"). `showsPremiumUpsell` is **removed** (donate card always shown). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Profile/ILProfileViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILProfileNavEvent` (**11 cases**: `.openPaywall` → `.openDonate`; **new** `.openMeritBook`, `.createFamilyTree`); new Inputs `meritBookTapped`, `createFamilyTreeTapped` (`premiumTapped` → `donateTapped`); version/build read from an injected `Bundle` (testable, default `.main`). |
| Presentation / Coordinator | `Presentation/Scenes/Profile/ILProfileCoordinator.swift` | `setViewControllers([ILProfileViewController])`; wired: `.editProfile`, `.openStats`, `.openSettings`, `.openNotifications`, `.openFamilyTree`, **`.createFamilyTree`** (`makeFamilyTreeCreateCoordinator`); TODO: `.openAwards`, `.openOffering`, `.openDonate`, `.openReminder`, `.openMeritBook`, `.openCommunity`. |
| Presentation / ViewController | `Presentation/Scenes/Profile/ILProfileViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. **v1.1**: the header is the first item of the scroll content (not a pinned band); as `UIScrollViewDelegate` it forwards `contentOffset.y` to the header (parallax `× 0.45`, stretch) and the compact bar (alpha `clamp((offset − 150) / 50, 0, 1)`); appends the version footer. |
| Feature-scoped views | `Presentation/Scenes/Profile/Views/ILProfileHeaderView.swift` (**reworked**: 250pt cover + gradient fade to canvas + edit pill with blur on cover + 84pt avatar overlapping −44pt + name/subtitle), `ILProfileCompactBarView.swift` (**new**: pinned name bar, alpha-driven), `ILProfileHeatmapCardView.swift` (21 columns), `ILProfileBadgesRowView.swift`, `ILProfileBadgeCardView.swift`, `ILProfileMeritCardView.swift`, `ILProfileDonateCardView.swift` (**renamed from `ILProfilePremiumCardView`**: lotus icon, "Ủng hộ InnerLamp", always shown), `ILProfileMenuCardView.swift` (**7 rows with icons**), `ILProfileVersionFooterView.swift` (**new**) | Section views. |
| Shared components | `ILStatSummaryCardView`, `ILHeatmapGridView`, `ILSettingRow` | `ILSettingRow` gains an **optional leading `icon`** (34pt rounded tile, template image tinted by token) — additive, existing call sites (Settings etc.) unchanged. `ILHeatmapGridView` already takes `columns` (21) — unchanged. |
| Design tokens / assets | `ILIcons`, `Assets.xcassets/Icons` | New template icons from the prototype `IL-Icon` glyphs: `row_tree`, `row_plus`, `row_bell`, `row_journal`, `row_gear`, `row_notif`, `row_temple`, `row_lotus` (+ `ILIcons` constants). `row_lamp` already exists for the merit card. Cover default image `profile_cover_default` is **not yet added** (TD-Profile-001); the cover shows the `canvasWarmEnd1 → tint` gradient and `setCoverImage(_:)` is the hook. New token `ILColors.coverPill`; `ILMetrics.settingIconTileSize` / `radiusSettingIconTile`. |

## Navigation flow

```
ILMainTabCoordinator (tab "Tôi")
  └─ ILProfileCoordinator                        (owned by Main, not AppCoordinator)
       setViewControllers([ILProfileViewController])  ← root of the Profile tab's nav
       .editProfile    → showEditProfile()   (ILEditProfileCoordinator)
       .openStats      → showStats()         (ILStatsCoordinator)
       .openSettings   → showSettings()      (ILSettingsCoordinator)
       .openNotifications → showNotifications() (ILNotificationsCoordinator)
       .openFamilyTree    → showFamilyTree() (ILFamilyTreeCoordinator)
       .createFamilyTree  → showFamilyTreeCreate() (ILFamilyTreeCreateCoordinator)   [v1.1]
       .openAwards / .openOffering / .openDonate / .openReminder / .openMeritBook / .openCommunity → TODO
```

## Header & scroll behaviour (v1.1)

Source: prototype `pfHeroH` / `pfImgT` / `pfBarOp` (`InnerLamp Prototype.dc.html`).

| Quantity | Value |
|---|---|
| Cover height (rest) | 250pt, full-bleed (ignores the 20pt screen gutter), `sunk2` background behind the image |
| Cover bottom fade | 90pt gradient, transparent → `canvas` |
| Edit pill | top-right 20pt inset, 56pt from top (below the status bar), blurred dark pill, text `#F7F2E8` 12pt/500 |
| Avatar | 84pt circle, 3pt `canvas` border + 1pt gold ring, overlaps cover by 44pt, initial in Cormorant 32pt |
| Name / subtitle | Cormorant 28pt/500 / Be Vietnam 12pt, "Pháp danh" part in link/gold colour |
| Parallax | cover image `translateY = round(offset × 0.45)` while scrolling up |
| Stretch | pull-down `p`: cover height `250 + p`, image scale `1 + p/500` |
| Compact bar | pinned, canvas background + 1pt bottom hairline, name in Cormorant 18pt; alpha `clamp((offset − 150)/50, 0, 1)`; non-interactive |

Per frame the cover only gets a transform and the compact bar an alpha
(AGENTS §4.6): no `UIImage(data:)`, no offscreen-rendered masks. The cover
container clips only while scrolling up (parallax) and does not clip while
pulling down (stretch grows past its frame).

## Data flow

1. `ILProfileViewModel` loads `useCase.getProfile()` (mock) and maps to
   `ILProfileStateModel` (formatted stats, heatmap alphas, badge models, merit
   summary, menu values, version text from the bundle).
2. Nav taps emit `.editProfile` / `.openStats` / `.openSettings` /
   `.openNotifications` / `.openFamilyTree` / `.createFamilyTree` (wired) or
   the six TODO events.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

`ILProfileUseCaseImpl.getProfile()` returns hardcoded data (name, 168 hours /
42-day streak / 9.7k chants, an 84-day heatmap, 3 badges, plan `.free`, a
5:30/6-day reminder, one community) with a `// TODO` comment. Completing this is
`tasks.md` Phase 3, blocked on the profile API contract.

## Design reference

Matches `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html`,
prototype screen `profile` (`isProfile` block, "Hồ sơ"). See `InnerLamp/Presentation/Scenes/Profile/README.md`
for the full design-vs-implementation comparison and changelog.
