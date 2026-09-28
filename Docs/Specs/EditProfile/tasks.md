# Tasks — EditProfile

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock data. Checked items reflect
> what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILEditProfileViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: `ILNavBar` + "Lưu", avatar + camera
      badge, four input cards, visibility group, danger zone — per design handoff
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILEditProfileAvatarView`,
      `ILEditProfileVisibilityCardView`, `ILEditProfileDangerZoneView`
- [x] Add shared `ILInputCardView` + tokens (`ILTypography.fieldValue`,
      `ILColors.borderMedium`/`dangerBorder`, `ILMetrics.radiusField`)
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `edit`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILEditProfileEntity` + `ILEditProfileVisibility`
- [x] Create `ILEditProfileStateModel`
- [x] Create `ILEditProfileUseCase` / `ILEditProfileUseCaseImpl` (getProfile mock,
      validateDisplayName real, saveProfile stub)
- [x] Create `ILEditProfileViewModel` (`Input -> Output`, `ILEditProfileNavEvent`,
      validate-then-save, initials helper)
- [x] Create `ILEditProfileCoordinator` (goBack/saved pop+finish; others TODO)
- [x] Wire `DIContainer.makeEditProfileUseCase/ViewModel/Coordinator`
- [x] Wire `ILProfileCoordinator` (`editProfile`) + `ILSettingsCoordinator`
      (`openProfile`)
- [x] Unit tests: `InnerLampTests/ILEditProfileViewModelTests.swift` (15 tests) —
      per-Input, save success/validation/failure, initials + validation helpers

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the profile read/update API contract(s), and how the single
> display-name field maps to the backend (see `requirements.md` Pending).

- [ ] Define the profile read/update API contract(s) + the display-name mapping
- [ ] Create `ILEditProfileDTO` + `ILEditProfileMapper` (once confirmed)
- [ ] Create `EditProfileEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILEditProfileRepository` protocol + implementation wrapping
      `NetworkService`
- [ ] Replace the mock `getProfile()` and the `saveProfile` stub with real calls
- [ ] Update `ILEditProfileViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Sub-destinations (pending, separate scope)

- [ ] Build the avatar picker / upload flow and wire `.changeAvatar`
- [ ] Build the visibility picker and wire `.openVisibility`
- [ ] Build the Change Password screen and wire `.changePassword`
- [ ] Build the delete-account flow (confirm + API) and wire `.deleteAccount`
- [ ] Update `InnerLamp/Presentation/Scenes/EditProfile/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/EditProfile/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/edit-profile.md` (OKF concept) — hold off until the
      profile API (Phase 3) lands. See `Docs/Specs/OKF.md`.
