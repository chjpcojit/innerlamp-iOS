# Tasks — Profile

Version: 1.5
Last updated: 2026-10-11
Status: in-progress (Phase 1–2 done; Phase 2b done except cover photo asset; Phase 2c done — device check pending; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock data. Checked items reflect
> what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILProfileViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header, stats card, heatmap, badges
      row, merit card, premium card, menu card — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILProfileHeaderView`,
      `ILProfileHeatmapCardView`, `ILProfileBadgesRowView`, `ILProfileBadgeCardView`,
      `ILProfileMeritCardView`, `ILProfilePremiumCardView`, `ILProfileMenuCardView`
- [x] Add shared `ILStatSummaryCardView` + `ILHeatmapGridView`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `profile`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILProfileEntity` + sub-entities/enums
- [x] Create `ILProfileStateModel` + section models
- [x] Create `ILProfileUseCase` / `ILProfileUseCaseImpl` (`getProfile()` — mock)
- [x] Create `ILProfileViewModel` (`Input -> Output`, `ILProfileNavEvent`, 9
      cases, Entity→StateModel mapping + formatting helpers)
- [x] Create `ILProfileCoordinator` (EditProfile/Stats/Settings/Notifications
      wired; awards/offering/paywall/reminder/community TODO)
- [x] Wire `DIContainer.makeProfileUseCase/ViewModel/Coordinator`
- [x] Wire `ILMainTabCoordinator` to use `ILProfileCoordinator` as the Me tab
- [x] Unit tests: `InnerLampTests/ILProfileViewModelTests.swift` (18 tests) —
      per-Input, state mapping (full/empty/paid), formatting helpers

## Phase 2b — v1.1 redesign (new prototype `profile`)

- [x] Add icon assets + `ILIcons` constants: `row_tree`, `row_plus`, `row_bell`,
      `row_journal`, `row_gear`, `row_notif`, `row_temple`, `row_lotus`
- [ ] Add default cover imageset `profile_cover_default` + `ILIcons` constant + `setCoverImage` call (blocked: no photo asset — TD-Profile-001)
- [x] `ILSettingRow`: optional leading `icon` (additive; Settings unaffected)
- [x] `ILProfileHeaderView`: 250pt cover, gradient fade, 84pt overlapping
      avatar, 28pt name (v1.2: edit pill removed)
- [x] `ILProfileCompactBarView` (new) + scroll-driven alpha / parallax / stretch
      in `ILProfileViewController`
- [x] Heatmap: 21 columns × 4 rows (`ILHeatmapGridView` / `ILProfileHeatmapCardView`)
- [x] Rename `ILProfilePremiumCardView` → `ILProfileDonateCardView`; always
      shown; remove `showsPremiumUpsell`
- [x] `ILProfileMenuCardView`: 7 icon rows (v1.2: Sửa hồ sơ, Gia phả dòng họ,
      Tạo gia phả mới, Chuông tỉnh thức, Cài đặt, Thông báo, Chùa tu tập)
- [x] `ILProfileVersionFooterView` + `versionText` from bundle
- [x] `ILProfileNavEvent`: `.openPaywall` → `.openDonate`; add `.openMeritBook`,
      `.createFamilyTree`; coordinator wires `.createFamilyTree`
- [x] Localization strings for new copy (vi + en)
- [x] Update `ILProfileViewModelTests` (new Inputs/events, version text, no
      upsell flag) — written and parses; not executed (⌘U blocked by the
      GRPCProtobufGenerator plug-in validation)
- [x] Record Assumption (cover image source) + Tech Debt (static cover,
      TODO destinations) under `Docs/Assumptions|Tech-Debt/Profile/`
- [x] `xcodebuild build` (generic/platform=iOS) green

## Phase 2c — v1.4 logout + no-flash render

- [x] `LogoutEndpoint` + `ILLogoutRepository` / `ILLogoutRepositoryImpl`
- [x] `ILSessionDataCleaner` / `ILSessionDataCleanerImpl` (Core Data `User`, `UserBirthProfile`, `Memorial`, `Lamp`)
- [x] `ILProfileUseCase.logout()` (best-effort revoke, clear tokens, local user, birth profile, memorial cache, lamps, chosen temple)
- [x] `ILAlert.confirm` + `ILConfirmDialogViewController` (+ tokens) and `ILAlertTests` cases
- [x] `ILProfileLogoutButtonView`; `ILProfileViewController` button + popup + error toast
- [x] `ILProfileViewModel`: `logoutConfirmed` Input, `.loggedOut` event, `isLoggingOut`, `logoutError` Output
- [x] Wire `ILProfileCoordinator.onLogout` → `ILMainTabCoordinator.onLogout` → `AppCoordinator.handleLoggedOut()`
- [x] `ILProfileViewController.updateUI`: per-section diff (no rebuild of unchanged cells); gradient layers no longer animate `frame` implicitly (header, merit card)
- [x] Tests: `ILProfileLogoutTests`, `ILProfileViewModelTests` logout cases — written; not executed (`InnerLampTests` does not build here: "Clang dependency scanning failure")
- [x] `xcodebuild build` (generic/platform=iOS) green
- [ ] Device check: logout flow end-to-end, scroll up/down right after first entering Profile shows no flash

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the profile / stats / badges API contract(s) (see
> `requirements.md` Pending). Everything below is blocked until a contract
> exists.

- [ ] Define the profile / stats / badges API contract(s) with the backend team
- [ ] Create `ILProfileDTO` + `ILProfileMapper` (once confirmed)
- [ ] Create `ProfileEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILProfileRepository` protocol + implementation (reusing
      `ILUserRepository` + network)
- [ ] Replace the mock data in `ILProfileUseCaseImpl.getProfile()` with real
      repository calls
- [ ] Add loading / error / offline states
- [ ] Update `ILProfileViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Unbuilt destinations (pending, separate scope)

- [ ] Build the Awards screen and wire `.openAwards`
- [x] Build the MeritBook ("Sổ công đức") screen and wire `.openMeritBook` (v1.3; see `Docs/Specs/MeritBook/`)
- [ ] Build the Ủng hộ InnerLamp (donate) screen and wire `.openDonate`
      (replaces the former Sen Vàng paywall item)
- [ ] Replace the bundled default cover with the per-user cover (source ⚠️)
- [ ] Build the Reminder screen and wire `.openReminder`
- [ ] Build/find the Temple screen and wire `.openCommunity(id:)`
- [ ] Add an avatar photo + role field (currently initial-only, fixed copy)
- [ ] Update `InnerLamp/Presentation/Scenes/Profile/README.md` changelog (note:
      its `editProfile`/`openStats` "TODO" rows are stale — both are wired)

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Profile/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/profile.md` (OKF concept) — hold off until the
      profile API (Phase 3) lands. See `Docs/Specs/OKF.md`.
