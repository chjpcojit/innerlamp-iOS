# FamilyTreeAddMember

## Overview

"Thêm người vào gia phả" — the form that adds one person to the clan book. The user picks how the
new person relates to an existing member ("Con của" / "Vợ / chồng của", with a picker to change who
that member is), then fills in the person (name, gender, birth year, living/deceased; living: current
residence; deceased: death year, lunar anniversary, burial place; optional note). A preview line shows
the resulting generation and parents. Pushed from the family tree's header "+" (relative = selected
member) and from the detail sheet's "Thêm con cháu" (relative = that member) by `ILFamilyTreeCoordinator`;
on success it pops back and the tree shows the new person, selected.
Design source: screen "Thêm người vào gia phả" in `Docs/InnerLamp project/IL-GiaPha.dc.html`. Spec:
`Docs/Specs/FamilyTreeAddMember/requirements.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | — (reuses `ILFamilyTreeEntity` / `ILFamilyMemberEntity`, which gained optional `residence` / `burialPlace`) | Done | `ILFamilyTreeAddMemberDraft` (raw form values) lives with the UseCase. |
| Presentation — StateModel | `ILFamilyTreeAddMemberStateModel.swift` | Done | Draft mirror, relative card + preview texts, picker rows, gender lock, one error, `isSubmitting`. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Not generated; see `TD-FamilyTreeAddMember-001`. |
| Domain — UseCase | `ILFamilyTreeAddMemberUseCase.swift` | Partial | Validation, placement (child / spouse rules, 7-generation cap) and member building are real and tested. `save(_:)` is a stub (`TD-FamilyTreeAddMember-001`). |
| Presentation — ViewModel | `ILFamilyTreeAddMemberViewModel.swift` | Done | 15 input triggers. |
| Presentation — ViewController | `ILFamilyTreeAddMemberViewController.swift` + `Views/ILFamilyTreeAddMemberRelativeCardView.swift`, `Views/ILFamilyTreeAddMemberPickerView.swift` | Done (not run on device) | Built from design-system components (`ILInputCardView`, `ILSegmentedToggleView`, `ILButton`, `ILNavBar`) and tokens. |
| Presentation — Coordinator | `ILFamilyTreeAddMemberCoordinator.swift` | Done | `.close`, `.saved`. |
| Tests | `ILFamilyTreeAddMemberViewModelTests.swift`, `ILFamilyTreeAddMemberUseCaseTests.swift` | Written, not executed | See Known gaps. |
| Wiring | `DIContainer` + `ILFamilyTreeCoordinator` | Done | Parent: FamilyTree (delegate hands the updated tree back). |

## Navigation events

`ILFamilyTreeAddMemberNavEvent`:
- `.close` — pop and `finish()`.
- `.saved(tree:memberID:)` — pop, call `delegate.familyTreeAddMemberDidSave(_:memberID:coordinator:)`, `finish()`.

## Known gaps / not implemented yet

- `save(_:)` persists nothing, so added people live only in memory — `TD-FamilyTreeAddMember-001`.
- Year lower bound (1700), the 7-generation cap and the free-text anniversary are unconfirmed — `AS-FamilyTreeAddMember-001`; a child of a married-in person is attached to that person's partner — `AS-FamilyTreeAddMember-002`; `residence` / `burialPlace` were added to the entity without an API contract — `AS-FamilyTreeAddMember-003`.
- The design's saved-confirmation toast is not shown — `TD-FamilyTreeAddMember-002`.
- No UI test — not requested. The test target does not build for `generic/platform=iOS` here (Clang dependency scanning), so the new unit tests were not compiled or executed.

## Changelog

- 2026-10-03 — Initial version.
