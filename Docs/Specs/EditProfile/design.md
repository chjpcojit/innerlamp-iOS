# Design — EditProfile

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full edit form with mock data; `saveProfile` stub, destinations not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

EditProfile ("Chỉnh sửa hồ sơ") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **pushed screen** inside the "Tôi" tab, owned by
`ILProfileCoordinator` (header "Sửa hồ sơ") and `ILSettingsCoordinator` (account
card). It has no delegate — `.goBack`/`.saved` pop, and the four remaining
destinations are TODOs. There is **no network**; `saveProfile` is a stub.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILEditProfileEntity.swift` | `ILEditProfileEntity` (displayName, phoneNumber, templeName, bio, 3 × visibility) + `ILEditProfileVisibility` (publicToSangha / onlyMe / anonymous). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/EditProfile/ILEditProfileUseCase.swift` | `getProfile()` (mock), `validateDisplayName(_:)` (real — required, trims whitespace), `saveProfile(_:)` (stub). Also `ILEditProfileValidationError`. |
| Presentation / State | `Presentation/Scenes/EditProfile/ILEditProfileStateModel.swift` | UI-only state: initials, raw input mirrors, visibility titles, `displayNameError`, `isSaving`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/EditProfile/ILEditProfileViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILEditProfileNavEvent` (6 cases); Entity↔StateModel mapping; validate-then-save flow; initials helper. |
| Presentation / Coordinator | `Presentation/Scenes/EditProfile/ILEditProfileCoordinator.swift` | `pushViewController`; `.goBack`/`.saved` → pop+finish; `.changeAvatar`/`.openVisibility`/`.changePassword`/`.deleteAccount` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/EditProfile/ILEditProfileViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/EditProfile/Views/ILEditProfileAvatarView.swift`, `ILEditProfileVisibilityCardView.swift`, `ILEditProfileDangerZoneView.swift` | Avatar, visibility card, danger-zone views. |
| Shared component | `DesignSystem/Components/ILInputCardView.swift` | New shared input card. |

## Navigation flow

```
ILProfileCoordinator (tab "Tôi")        ILSettingsCoordinator (account card)
  └─ showEditProfile() → ILEditProfileCoordinator   (no delegate)
       push ILEditProfileViewController
       (.goBack / .saved) → pop + finish()
       (.changeAvatar / .openVisibility / .changePassword / .deleteAccount) → TODO
```

## Data flow

1. `ILEditProfileViewModel` loads `useCase.getProfile()` (mock) and maps to
   `ILEditProfileStateModel` (initials, visibility titles).
2. Field edits mirror into the state model and clear `displayNameError`.
3. `handleSave()` validates (required display name) → builds the edited entity
   (trimmed) → `saveProfile` (stub) → `.saved` on success / `.failure` on error.

There is no network call and no Step-by-step Flow.

## Deliberately stub / mock

`ILEditProfileUseCaseImpl.getProfile()` returns mock data (matching the
prototype "Diệu Tâm"), and `saveProfile` is a `print("TODO: …")` stub.
Completing this is `tasks.md` Phase 3, blocked on the profile API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `edit`. See `InnerLamp/Presentation/Scenes/EditProfile/README.md`
for the full design-vs-implementation comparison and changelog.
