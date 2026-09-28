# Tasks — Profile

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

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
- [ ] Build the Offering screen and wire `.openOffering`
- [ ] Build the Sen Vàng paywall modal and wire `.openPaywall`
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
