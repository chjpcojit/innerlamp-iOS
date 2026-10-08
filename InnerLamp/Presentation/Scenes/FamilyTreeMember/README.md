# FamilyTreeMember

## Overview

"Hồ sơ thành viên" — the full profile of one person in the clan book, on a single screen with two
modes like the prototype. View mode: medallion, name, meta, status / role / "Với bạn" chips, the
THÔNG TIN card, the biography, the TƯỞNG NIỆM tiles (deceased only) and the QUAN HỆ list. Edit mode
("Sửa"): the form (CƠ BẢN, TƯỞNG NIỆM for the deceased, TÂM LINH, TIỂU SỬ) with per-field errors;
saving returns to view mode and hands the updated tree back to the family tree.
Pushed from the family tree's detail sheet ("Hồ sơ đầy đủ") by `ILFamilyTreeCoordinator`.
Design source: screen "Hồ sơ thành viên" in `Docs/InnerLamp project/IL-GiaPha.dc.html`. Spec:
`Docs/Specs/FamilyTreeMember/requirements.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | — (reuses `ILFamilyTreeEntity` / `ILFamilyMemberEntity`, which gained `dharmaName` / `tabletTemple`) | Done | `ILFamilyTreeMemberDraft` (raw form values) lives with the UseCase; see `AS-FamilyTreeMember-001`. |
| Presentation — StateModel | `ILFamilyTreeMemberStateModel.swift` | Done | Mode, resolved view texts, draft, one error, `isSubmitting`. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Not generated; see `TD-FamilyTreeMember-001`. |
| Domain — UseCase | `ILFamilyTreeMemberUseCase.swift` | Partial | Draft building, validation and member replacement are real. `save(_:)` is a stub (`TD-FamilyTreeMember-001`). |
| Presentation — ViewModel | `ILFamilyTreeMemberViewModel.swift` | Done | 20 input triggers. |
| Presentation — ViewController | `ILFamilyTreeMemberViewController.swift` + `Views/` (hero, pill, info card, note, memorial tiles, relation row) | Done (not run on device) | Built from `ILNavBar`, `ILInputCardView`, `ILSegmentedToggleView`, `ILButton` and tokens. |
| Presentation — Coordinator | `ILFamilyTreeMemberCoordinator.swift` | Done | `.back`, `.saved`, `.openMember`; memorial / temple events are TODO stubs. |
| Tests | `ILFamilyTreeMemberViewModelTests.swift`, `ILFamilyTreeMemberUseCaseTests.swift` | Written, not executed | See Known gaps. |
| Wiring | `DIContainer` + `ILFamilyTreeCoordinator` | Pending | Done by the FamilyTree rework, not by this scene. |

## Navigation events

`ILFamilyTreeMemberNavEvent`:
- `.back` — pop and `finish()`.
- `.saved(tree:memberID:)` — call `delegate.familyTreeMemberDidSave(_:memberID:coordinator:)`; the screen stays open.
- `.openMember(id)` — pop, call `delegate.familyTreeMemberDidRequestOpen(memberID:coordinator:)`, `finish()`.
- `.remind`, `.lightLamp`, `.chant`, `.openTemple` — one-line `print("TODO: ...")` stubs (`TD-FamilyTreeMember-003`).

## Known gaps / not implemented yet

- `save(_:)` persists nothing — `TD-FamilyTreeMember-001`.
- No portrait photo; the medallion replaces it — `TD-FamilyTreeMember-002`.
- Nhắc giỗ / Thắp đèn / Tụng kinh and the temple link do nothing yet — `TD-FamilyTreeMember-003`.
- Pháp danh / Bài vị thờ tại were added to the entity without an API contract — `AS-FamilyTreeMember-001`; validation limits — `AS-FamilyTreeMember-002`; the back chip is "Hủy" in edit mode — `AS-FamilyTreeMember-003`.
- No UI test — not requested. Unit tests were written but not compiled or executed (no simulator).

## Changelog

- 2026-10-04 — initial build from the "Hồ sơ thành viên" prototype screen via il-screen-builder.
