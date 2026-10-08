# Design — FamilyTreeChronicle

Version: 1.0
Last updated: 2026-10-04
Source: requirements.md v1.0

## Architecture

| Layer | File | Notes |
|---|---|---|
| Domain — Entity | `Domain/Entities/ILFamilyChronicleEntity.swift` | `ILFamilyChronicleEntity`, `ILFamilyMilestoneEntity`; stored on `ILFamilyTreeEntity.chronicle`. |
| Domain — UseCase | `Domain/UseCases/FamilyTreeChronicle/ILFamilyTreeChronicleUseCase.swift` | `makeDraft`, `apply` (pure validation), `clanHeadCandidates`, `changeClanHead` (pure), `save` (stub). |
| Presentation | `Presentation/Scenes/FamilyTreeChronicle/` | StateModel, ViewModel, ViewController, Coordinator, `Views/`. |

## Navigation

`ILFamilyTreeChronicleCoordinator` is a child of `ILFamilyTreeCoordinator` (same flow as AddMember / Create). Events: `.back`, `.updated([tree])` (delegate, screen stays), `.openMember(treeID:memberID:)` (pop + delegate), `.remindFounderAnniversary` (TODO print).

## State

The ViewModel owns a working `[ILFamilyTreeEntity]` and the active book index. View mode texts are derived from the active book on every change (`refresh()`); edit mode reads `draft`. A saved edit replaces the active book, calls `save`, then emits `.updated(allBooks)`.

## UI

One scroll screen under `ILNavBar` ("Sửa" / "Xong"). Sections are stacks whose view / edit variants are shown or hidden. The clan-head picker is a bottom sheet over a scrim; the confirmation uses `ILAlert.dialog`; the save confirmation uses `ILAlert.success`.

- The design's shrine photo slot is not built (`TD-FamilyTreeChronicle-002`).
- The lacquered plaque uses the `bark` token (design `#5A2A1E` has no token).
