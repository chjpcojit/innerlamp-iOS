# Design — FamilyTreeMember

Version: 1.0
Last updated: 2026-10-04
Status: implemented (code written; build, unit tests and device run pending)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

UIKit, MVVM-C. One screen with two modes (`ILFamilyTreeMemberMode.view` / `.edit`), switched inside the same ViewController like the prototype's `pfView` / `pfEditing`. No network call yet (`save(_:)` is a stub, `TD-FamilyTreeMember-001`), so no Step-by-step Flow section is required. Colours, fonts and metrics come from `ILColors.FamilyTree` / `ILTypography` / `ILMetrics.FamilyTree`; spacing with no token lives in a private `Layout` enum.

## Layers & components

| Component | File | Notes |
|---|---|---|
| UseCase | `Domain/UseCases/FamilyTreeMember/ILFamilyTreeMemberUseCase.swift` | `makeDraft(from:)`, `updateMember(_:memberID:in:currentYear:)` (pure validation + replacement), `save(_:)` stub |
| StateModel | `ILFamilyTreeMemberStateModel.swift` | Mode, resolved view texts (facts, relations), `draft`, one error, `isSubmitting` |
| ViewModel | `ILFamilyTreeMemberViewModel.swift` | 20 input triggers; owns the working tree copy; view texts come from `ILFamilyTreeGraph` + `ILFamilyTreeFormatter` |
| ViewController | `ILFamilyTreeMemberViewController.swift` | `ILNavBar` (back / "Hồ sơ" / "Sửa" ↔ back-as-Hủy / "Sửa hồ sơ" / "Lưu"), scroll view with a view stack and an edit stack |
| Views | `Views/` | Hero (medallion, name, chips), pill, info card, note / empty box, memorial tiles, relation row |
| Coordinator | `ILFamilyTreeMemberCoordinator.swift` | `.back`, `.saved`, `.openMember`; stubs for memorial/temple events |

## Navigation contract

`ILFamilyTreeMemberNavEvent`: `.back`, `.saved(tree:memberID:)`, `.openMember(String)`, `.remind`, `.lightLamp`, `.chant`, `.openTemple`.
Delegate `ILFamilyTreeMemberCoordinatorDelegate`: `familyTreeMemberDidSave` (screen stays open) and `familyTreeMemberDidRequestOpen` (screen already popped). Parent: `ILFamilyTreeCoordinator`.

## Notes

- ⚠️ Not confirmed: the portrait photo and the destinations of the memorial tiles (see the TD entries).
- Edit mode's back chip acts as "Hủy" (`AS-FamilyTreeMember-003`).
