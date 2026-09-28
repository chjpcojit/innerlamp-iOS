# Design — Profile

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full tab UI with mock data; destinations partially built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Profile ("Tôi") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
**tab 4** of `ILMainTabBarController`, so `ILProfileCoordinator` is owned by
`ILMainTabCoordinator` (which gives it its own `BaseNavigationController`).
There is **no network** — the UseCase returns static mock data.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILProfileEntity.swift` | `ILProfileEntity` (name, dharmaName, practiceStats, journalEntriesPerDay, recentBadges, totalBadgeCount, offeringCount, lanternCount, plan, reminder, community) + sub-entities/enums (`ILProfilePlan`, `ILProfilePracticeStatsEntity`, `ILProfileBadgeCategory`, `ILProfileBadgeEntity`, `ILProfileReminderEntity`, `ILProfileCommunityEntity`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Profile/ILProfileUseCase.swift` | `getProfile()` — static mock (TODO: repository → network). |
| Presentation / State | `Presentation/Scenes/Profile/ILProfileStateModel.swift` | UI-only state: header, stat models, heatmap (intensities), badge models, merit summary, `showsPremiumUpsell`, menu values. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Profile/ILProfileViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILProfileNavEvent` (9 cases); Entity→StateModel mapping + compact-count / reminder / heatmap / initial formatting. |
| Presentation / Coordinator | `Presentation/Scenes/Profile/ILProfileCoordinator.swift` | `setViewControllers([ILProfileViewController])`; `.editProfile`/`.openStats`/`.openSettings`/`.openNotifications` wired; the other 5 TODO. |
| Presentation / ViewController | `Presentation/Scenes/Profile/ILProfileViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Profile/Views/ILProfileHeaderView.swift`, `ILProfileHeatmapCardView.swift`, `ILProfileBadgesRowView.swift`, `ILProfileBadgeCardView.swift`, `ILProfileMeritCardView.swift`, `ILProfilePremiumCardView.swift`, `ILProfileMenuCardView.swift` | The seven section views. |
| Shared components | `ILStatSummaryCardView`, `ILHeatmapGridView` | Reused stat-summary and heatmap-grid views. |

## Navigation flow

```
ILMainTabCoordinator (tab "Tôi")
  └─ ILProfileCoordinator                        (owned by Main, not AppCoordinator)
       setViewControllers([ILProfileViewController])  ← root of the Profile tab's nav
       .editProfile    → showEditProfile()   (ILEditProfileCoordinator)
       .openStats      → showStats()         (ILStatsCoordinator)
       .openSettings   → showSettings()      (ILSettingsCoordinator)
       .openNotifications → showNotifications() (ILNotificationsCoordinator)
       .openAwards / .openOffering / .openPaywall / .openReminder / .openCommunity → TODO
```

## Data flow

1. `ILProfileViewModel` loads `useCase.getProfile()` (mock) and maps to
   `ILProfileStateModel` (formatted stats, heatmap alphas, badge models, merit
   summary, plan upsell, menu values).
2. Nav taps emit `.editProfile` / `.openStats` / `.openSettings` /
   `.openNotifications` (wired) or the five TODO events.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

`ILProfileUseCaseImpl.getProfile()` returns hardcoded data (name, 168 hours /
42-day streak / 9.7k chants, an 84-day heatmap, 3 badges, plan `.free`, a
5:30/6-day reminder, one community) with a `// TODO` comment. Completing this is
`tasks.md` Phase 3, blocked on the profile API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `profile`. See `InnerLamp/Presentation/Scenes/Profile/README.md`
for the full design-vs-implementation comparison and changelog.
