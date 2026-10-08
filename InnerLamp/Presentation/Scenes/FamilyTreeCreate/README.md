# FamilyTreeCreate

## Overview

"Tạo gia phả" — the form that starts a new clan book: the clan name and hometown, then the founder
(Thủy tổ, đời 1: name, birth year, living/deceased, and for a deceased founder the death year and
lunar death anniversary) and an optional wife. A header card follows what the user types
("Họ …" / "quê gốc · Thủy tổ …"). Pushed from the family tree's empty state ("Tạo gia phả mới",
`ILFamilyTreeCoordinator`); on success it pops back and the tree screen shows the new tree.
Design source: screen "Tạo gia phả" in `Docs/InnerLamp project/IL-GiaPha.dc.html`. Spec:
`Docs/Specs/FamilyTreeCreate/requirements.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | — (reuses `ILFamilyTreeEntity` / `ILFamilyMemberEntity`) | Done | The result of creating is a `ILFamilyTreeEntity`; `ILFamilyTreeCreateDraft` (raw form values) lives with the UseCase. |
| Presentation — StateModel | `ILFamilyTreeCreateStateModel.swift` | Done | Raw field mirrors, header texts, one error (field + message), `isSubmitting`. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Not generated; see `TD-FamilyTreeCreate-001`. |
| Domain — UseCase | `ILFamilyTreeCreateUseCase.swift` | Partial | Validation, "Họ " prefixing, anniversary parsing and tree building are real and tested. `save(_:)` is a stub (`TD-FamilyTreeCreate-001`). |
| Presentation — ViewModel | `ILFamilyTreeCreateViewModel.swift` | Done | 11 input triggers. |
| Presentation — ViewController | `ILFamilyTreeCreateViewController.swift` + `Views/ILFamilyTreeCreateHeaderCardView.swift` | Done (not run on device) | Built from design-system components (`ILInputCardView`, `ILSegmentedToggleView`, `ILButton`, `ILNavBar`) and tokens. |
| Presentation — Coordinator | `ILFamilyTreeCreateCoordinator.swift` | Done | `.back`, `.created`. |
| Tests | `ILFamilyTreeCreateViewModelTests.swift`, `ILFamilyTreeCreateUseCaseTests.swift` | Done | Not run — see Known gaps. |
| Wiring | `DIContainer` + `ILFamilyTreeCoordinator` | Done | Section coordinator parent: FamilyTree (delegate hands the new tree back). |

## Navigation events

`ILFamilyTreeCreateNavEvent`:
- `.back` — pop and `finish()`.
- `.created(ILFamilyTreeEntity)` — pop, call `delegate.familyTreeCreateDidCreate(_:coordinator:)`, `finish()`.

## Known gaps / not implemented yet

- `save(_:)` persists nothing, so the new tree exists only in memory until the app is closed — `TD-FamilyTreeCreate-001`.
- The design's "Đã tạo gia phả … Bấm + để thêm con cháu." toast is not shown, and the "+" button the footnote mentions does not exist yet — `TD-FamilyTreeCreate-002`.
- Year limits use the current year instead of the design's fixed 2026 — `AS-FamilyTreeCreate-001`; the anniversary is read from text and rejected if unreadable — `AS-FamilyTreeCreate-002`; the founder is always male and the wife female — `AS-FamilyTreeCreate-003`.
- No UI test — not requested. Unit tests were type-checked but not executed (no simulator; XCTest needs a simulator or signed device).

## Changelog

- 2026-10-03 — initial build from the "Tạo gia phả" prototype screen via il-screen-builder.
