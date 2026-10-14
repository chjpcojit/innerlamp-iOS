# Design — AddTemple

Version: 1.2
Last updated: 2026-10-11
Status: in-progress

> See `changelog.md` in this folder for the version history of this spec.

## Layers & components

| Layer | Type | Responsibility |
|---|---|---|
| Domain | `ILTempleProposalEntity` | name, province, ward, address of the proposed temple |
| Domain | `ILAdministrativeUnitRepository` | provinces and wards-by-province from the server (dropdown source; shared with other screens) |
| Domain | `ILAddTempleUseCase` / `ILAddTempleUseCaseImpl` | load metadata, validate (required, duplicate) and normalise the name |
| Data | `ILAdministrativeUnitRepositoryImpl` | `GET /v1/administrative-units/new/provinces` and `.../provinces/{code}/wards` (public, HTTP-cached 24h) |
| Presentation | `ILAddTempleStateModel` | form values, province/ward options + loading flags, error message/field |
| Presentation | `ILAddTempleViewModel` | Input → Output, emits `ILAddTempleNavEvent` (`back`, `submitted`) |
| Presentation | `ILAddTempleViewController` | `ILNavBar`, name/address `ILField`, province/ward `ILSelectFieldView`, error line, pinned `ILButton`s; presents `ILOptionPickerViewController` sheets |
| Presentation | `ILAddTempleCoordinator` | pushes the screen; delegate returns the proposal to `ILSignUpCoordinator` |

## Step-by-step flow

1. Sign-up picker "Thêm thông tin chùa" → `ILSignUpViewModel.openAddTemple(prefillName, existingPlaces)`.
2. `ILSignUpCoordinator` creates `ILAddTempleCoordinator` (child) and pushes the screen.
3. Province tap → `ILOptionPickerViewController` (options from `provinceOptions`, loaded on `viewDidLoad`);
   choosing a province clears the ward and calls `loadWards(provinceCode:)` with the chosen province's `code`; ward tap opens the sheet with
   `wardOptions` / skeleton while `isLoadingWards`. A stale ward response (province changed) is dropped.
4. Submit → `validate` → on error render message; on success `makeProposal` → `.submitted`.
5. `ILSignUpViewModel.applyProposedPlace` inserts it first in the options, sets `ordinationPlace` and
   `selectedOrdinationPlaceID`; the picker marks the row. No network call (⚠️ Not confirmed).
