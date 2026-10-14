# Design — Profile

Version: 1.5
Last updated: 2026-10-11
Status: in-progress — v1.4 logout applied; mock stats; destinations partially built

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
| Domain / UseCase | `Domain/UseCases/Profile/ILProfileUseCase.swift` | `getProfile()` — static mock (TODO: repository → network); `loadProfile()` — account fields from `GET /v1/users/me` (name = `full_name`, email when absent); **`logout()` (v1.4)** — best-effort `ILLogoutRepository.revokeSession()` (skipped when no access token), then deletes the access + refresh tokens (`KeychainService`, missing item tolerated), the account-scoped Core Data rows via `ILSessionDataCleaner` (`User`, `UserBirthProfile`, `Memorial`, `Lamp`) and the chosen-temple UserDefaults keys; throws `ILProfileLogoutError.storageFailed` only when the local clear fails. |
| Domain / Repository (v1.4) | `Domain/Repositories/ILLogoutRepository.swift` | `revokeSession()`; impl `Data/Repositories/ILLogoutRepositoryImpl.swift` → `LogoutEndpoint` (`POST /v1/auth/logout`, response `{"success":true}`, no `data`). |
| Presentation / State | `Presentation/Scenes/Profile/ILProfileStateModel.swift` | v1.4: **`isLoggingOut`** (disables the logout button). UI-only state: header, stat models, heatmap (intensities), badge models, merit summary, menu values (reminder, community; the family-tree row value is not modelled until its source is confirmed), **`versionText` / `buildText`** ("InnerLamp · Phiên bản x" / "Bản dựng y"). `showsPremiumUpsell` is **removed** (donate card always shown). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Profile/ILProfileViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILProfileNavEvent` (**11 cases** → v1.2: **10 cases**, `.openMeritBook` removed; `.openPaywall` → `.openDonate`; **new** `.createFamilyTree`); new Input `createFamilyTreeTapped` (`meritBookTapped` removed in v1.2) (`premiumTapped` → `donateTapped`); version/build read from an injected `Bundle` (testable, default `.main`). |
| Presentation / Coordinator | `Presentation/Scenes/Profile/ILProfileCoordinator.swift` | v1.4: `.loggedOut` → `onLogout?()` (closure chain `ILProfileCoordinator` → `ILMainTabCoordinator.onLogout` → `AppCoordinator.handleLoggedOut()`, which drops `ILMainTabCoordinator` and calls `showLogin()`). `setViewControllers([ILProfileViewController])`; wired: `.editProfile`, `.openStats`, `.openSettings`, `.openNotifications`, `.openFamilyTree`, **`.createFamilyTree`** (`makeFamilyTreeCreateCoordinator`), **`.openMeritBook`** (`makeMeritBookCoordinator`, v1.3); TODO: `.openAwards`, `.openDonate`, `.openReminder`, `.openCommunity`. |
| Presentation / ViewController | `Presentation/Scenes/Profile/ILProfileViewController.swift` | v1.4: logout button → `ILAlertPresenter.shared.show(.confirm …)`; only the confirmed choice is sent to the ViewModel (`logoutConfirmed`); `Output.logoutError` → `showError` toast; `updateUI` diffs against the last rendered `ILProfileStateModel` per section (no teardown of unchanged cells). `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. **v1.1**: the header is the first item of the scroll content (not a pinned band); as `UIScrollViewDelegate` it forwards `contentOffset.y` to the header (parallax `× 0.45`, stretch) and the compact bar (alpha `clamp((offset − 150) / 50, 0, 1)`); appends the version footer. |
| Feature-scoped views | `Presentation/Scenes/Profile/Views/ILProfileHeaderView.swift` (**reworked**: 250pt cover + gradient fade to canvas + 84pt avatar (v1.2: edit pill removed, no `onEditTapped`) overlapping −44pt + name/subtitle), `ILProfileCompactBarView.swift` (**new**: pinned name bar, alpha-driven), `ILProfileHeatmapCardView.swift` (21 columns), `ILProfileBadgesRowView.swift`, `ILProfileBadgeCardView.swift`, `ILProfileMeritCardView.swift`, `ILProfileDonateCardView.swift` (**renamed from `ILProfilePremiumCardView`**: lotus icon, "Ủng hộ InnerLamp", always shown), `ILProfileMenuCardView.swift` (**7 rows with icons**; v1.2: first row "Sửa hồ sơ" / `row_user`, "Sổ công đức" row removed), `ILProfileVersionFooterView.swift` (**new**), `ILProfileLogoutButtonView.swift` (**new v1.4**: 52pt card, 1pt `border`, radius 20, label `ILTypography.destructiveRowLabel` in `ILColors.danger`) | Section views. |
| Shared popup (v1.4) | `Presentation/Common/DesignSystem/Components/Alert/ILConfirmDialogViewController.swift`, `ILAlert.confirm(title:message:cancel:confirm:)` | Prototype `loShow` popup: card max 280pt / 44pt margin / radius 16, title (`title2`) + message (`bodyCompact`, `inkDim`), hairline, two 46pt cells (cancel `link`, confirm `danger` semibold); scrim `ILColors.Alert.scrimConfirm`; scrim tap = cancel. Tokens: `ILMetrics.Alert.confirm*`, `ILMetrics.shadowAlertConfirm`, `ILTypography.confirmDialogButton`. |
| Shared components | `ILStatSummaryCardView`, `ILHeatmapGridView`, `ILSettingRow` | `ILSettingRow` gains an **optional leading `icon`** (34pt rounded tile, template image tinted by token) — additive, existing call sites (Settings etc.) unchanged. `ILHeatmapGridView` already takes `columns` (21) — unchanged. |
| Design tokens / assets | `ILIcons`, `Assets.xcassets/Icons` | New template icons from the prototype `IL-Icon` glyphs: `row_user` (v1.2), `row_tree`, `row_plus`, `row_bell`, `row_journal`, `row_gear`, `row_notif`, `row_temple`, `row_lotus` (+ `ILIcons` constants). `row_lamp` already exists for the merit card. Cover default image `profile_cover_default` is **not yet added** (TD-Profile-001); the cover shows the `canvasWarmEnd1 → tint` gradient and `setCoverImage(_:)` is the hook. New token `ILColors.coverPill`; `ILMetrics.settingIconTileSize` / `radiusSettingIconTile`. |

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
       .openMeritBook     → showMeritBook() (ILMeritBookCoordinator)   [v1.3]
       .loggedOut         → onLogout?()   → ILMainTabCoordinator.onLogout → AppCoordinator.handleLoggedOut() → showLogin()   [v1.4]
       .openAwards / .openReminder / .openCommunity → TODO
```

## Header & scroll behaviour (v1.1)

Source: prototype `pfHeroH` / `pfImgT` / `pfBarOp` (`InnerLamp Prototype.dc.html`).

| Quantity | Value |
|---|---|
| Cover height (rest) | 250pt, full-bleed (ignores the 20pt screen gutter), `sunk2` background behind the image |
| Cover bottom fade | 90pt gradient, transparent → `canvas` |
| Edit pill | **Removed in v1.2** — "Sửa hồ sơ" is now the first row of the menu card (`user` icon, chevron) |
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

## Logout flow (v1.4) — Step-by-step

| # | Trigger | Pre-condition | Action | Success | Failure |
|---|---|---|---|---|---|
| 1 | Tap "Đăng xuất" | Not already logging out | View shows `ILAlert.confirm` | Popup visible | — |
| 2 | Tap "Hủy" / scrim | Popup visible | Popup closes | User stays signed in | — |
| 3 | Tap "Đăng xuất" in popup | Popup visible | `logoutConfirmed` → `useCase.logout()`; state `isLoggingOut = true` | → step 4 | — |
| 4 | (use case) | Access token present | `POST /v1/auth/logout` (access token as bearer) | Session revoked → step 5 | Error ignored → step 5 (TD-Profile-004) |
| 5 | (use case) | — | Delete `access_token`, `refresh_token` (missing = ok), `ILSessionDataCleaner.clearUserScopedData()` (Core Data `User`, `UserBirthProfile`, `Memorial`, `Lamp`) + UserDefaults `sangha.myTempleID` / `sangha.myTempleSnapshot` | `.loggedOut` → Login | `ILProfileLogoutError.storageFailed` → toast, button re-enabled, stay on Profile |

A 401 on step 4 goes through the shared refresher; if the session is dead it posts
`.authSessionDidExpire`, which `AppCoordinator` also handles — both handlers guard on
`ILMainTabCoordinator` still being a child, so the user reaches Login once.

Other than logout there is no network call on this screen except `GET /v1/users/me`.

## Deliberately mock / stub

`ILProfileUseCaseImpl.getProfile()` returns hardcoded data (name, 168 hours /
42-day streak / 9.7k chants, an 84-day heatmap, 3 badges, plan `.free`, a
5:30/6-day reminder, one community) with a `// TODO` comment. Completing this is
`tasks.md` Phase 3, blocked on the profile API contract.

## Design reference

Matches `Docs/innerlamp-project/project/InnerLamp Prototype.dc.html`,
prototype screen `profile` (`isProfile` block, "Hồ sơ"). See `InnerLamp/Presentation/Scenes/Profile/README.md`
for the full design-vs-implementation comparison and changelog.
