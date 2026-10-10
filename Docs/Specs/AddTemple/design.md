# Design — AddTemple

Version: 1.0
Last updated: 2026-10-10
Status: in-progress

> See `changelog.md` in this folder for the version history of this spec.

## Layers & components

| Layer | Type | Responsibility |
|---|---|---|
| Domain | `ILTempleProposalEntity` | name, province, address of the proposed temple |
| Domain | `ILAddTempleUseCase` / `ILAddTempleUseCaseImpl` | validate (required, duplicate) and normalise the name |
| Presentation | `ILAddTempleStateModel` | form values + error message/field |
| Presentation | `ILAddTempleViewModel` | Input → Output, emits `ILAddTempleNavEvent` (`back`, `submitted`) |
| Presentation | `ILAddTempleViewController` | `ILNavBar`, 3 `ILField`, error line, pinned `ILButton`s |
| Presentation | `ILAddTempleCoordinator` | pushes the screen; delegate returns the proposal to `ILSignUpCoordinator` |

## Step-by-step flow

1. Sign-up picker "Thêm thông tin chùa" → `ILSignUpViewModel.openAddTemple(prefillName, existingPlaces)`.
2. `ILSignUpCoordinator` creates `ILAddTempleCoordinator` (child) and pushes the screen.
3. Submit → `validate` → on error render message; on success `makeProposal` → `.submitted`.
4. `ILSignUpViewModel.applyProposedPlace` inserts it first in the options, sets `ordinationPlace` and
   `selectedOrdinationPlaceID`; the picker marks the row. No network call (⚠️ Not confirmed).
