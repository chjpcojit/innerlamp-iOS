# FamilyTreeChronicle

## Overview

"Phả ký dòng họ" — the written record of a clan book on one screen with a view mode and an edit
mode (nav-bar "Sửa" / "Xong"): Nguồn gốc (founder card + origin story), Mốc lịch sử (timeline,
add / edit / delete milestones), Nhà thờ họ (name, address, keeper with "Đổi", giỗ tổ, chạp họ),
Gia huấn (hoành phi, câu đối, lời dạy) and Người tiêu biểu. With more than one book (nội / ngoại)
a tab row switches between them. "Đổi" opens a sheet of eligible men, then a confirmation, and
moves the clan-head flag. Empty sections show a dashed "Chưa có … Bấm để …" card that enters edit
mode — that is the "add" path. Opened by `ILFamilyTreeCoordinator` from the tree header's 譜 seal and
from the switcher menu's "Phả ký dòng họ" row; edits are handed back through the delegate.
Design source: screen "Phả ký dòng họ" in `Docs/InnerLamp project/IL-GiaPha.dc.html`. Spec:
`Docs/Specs/FamilyTreeChronicle/requirements.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | — (`ILFamilyChronicleEntity.swift`, `ILFamilyTreeEntity.chronicle`) | Done | Shared with the tree; milestones are `ILFamilyMilestoneEntity`. `ILFamilyTreeChronicleDraft` (raw form text) lives with the UseCase. |
| Presentation — StateModel | `ILFamilyTreeChronicleStateModel.swift` | Done | View-mode texts, draft mirror, tabs, picker rows, pending head change, toast token. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Not generated; see `TD-FamilyTreeChronicle-001`. |
| Domain — UseCase | `ILFamilyTreeChronicleUseCase.swift` | Partial | Draft, validation / apply, clan-head candidates and change are real. `save(_:)` is a stub (`TD-FamilyTreeChronicle-001`). |
| Presentation — ViewModel | `ILFamilyTreeChronicleViewModel.swift` | Done | 16 input triggers. |
| Presentation — ViewController | `ILFamilyTreeChronicleViewController.swift` + `Views/` | Done (not built or run) | Built from design-system components (`ILNavBar`, `ILInputCardView`, `ILSegmentedToggleView`, `ILSectionEyebrowView`, `ILAlert`) and `ILColors.FamilyTree`. |
| Presentation — Coordinator | `ILFamilyTreeChronicleCoordinator.swift` | Done | `.back`, `.updated`, `.openMember`, `.remindFounderAnniversary` (stub). |
| Tests | `ILFamilyTreeChronicleViewModelTests.swift`, `ILFamilyTreeChronicleUseCaseTests.swift` | Written, not executed | See Known gaps. |
| Wiring | `DIContainer` + `ILFamilyTreeCoordinator` | Pending | Done by the FamilyTree rework, not by this scene. |

## Navigation events

`ILFamilyTreeChronicleNavEvent`:
- `.back` — pop and `finish()`.
- `.updated([ILFamilyTreeEntity])` — call `delegate.familyTreeChronicleDidUpdate(_:coordinator:)`; the screen stays.
- `.openMember(treeID:memberID:)` — pop, call `delegate.familyTreeChronicleDidRequestOpen(...)`, `finish()`.
- `.remindFounderAnniversary(treeID:memberID:)` — one-line TODO print (`TD-FamilyTreeChronicle-003`).

## Known gaps / not implemented yet

- `save(_:)` persists nothing — `TD-FamilyTreeChronicle-001`.
- The shrine photo slot of the design is not built — `TD-FamilyTreeChronicle-002`; the "Nhắc giỗ tổ" button is a stub and does not turn into "✓ Đã nhắc…" — `TD-FamilyTreeChronicle-003`; no discard prompt when leaving edit mode — `TD-FamilyTreeChronicle-004`.
- Clan-head candidates (living blood men from generation 2) and milestone-year rules are unconfirmed — `AS-FamilyTreeChronicle-001`, `-003`; anyone can edit, though the design footer hints at manager vs. descendant roles — `AS-FamilyTreeChronicle-002`.
- The lacquered plaque uses the `bark` token; the design's `#5A2A1E` has no token.
- No UI test — not requested. Unit tests were written but not compiled or executed (no simulator).

## Changelog

- 2026-10-04 — Initial version, built from the "Phả ký dòng họ" prototype screen via il-screen-builder.
