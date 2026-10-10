# FamilyTree

## Overview

"Cây gia phả" — a zoomable, scrollable illustration of a clan: a tree whose trunk is the founder
(Thủy tổ) and whose newest generation is at the top. Tap a person to select them (gold lineage line
back to the founder + a bottom sheet with facts, relations and lineage); filter by generation,
search by name (diacritic-insensitive), zoom with the buttons or by pinching, and jump back to the
founder. Several books are supported: the header's clan name opens a switcher menu (father's book "nội", mother's book "ngoại", the merged "Nội – ngoại của bạn" view, a link to the clan chronicle and "Tạo gia phả mới"); the red 譜 seal opens the chronicle. "Hồ sơ đầy đủ" opens the member profile (view + edit).
Pushed from the "Xem gia phả" button on the Sổ giỗ chạp list (`ILMemorialCoordinator`);
design source: `Docs/InnerLamp project/IL-GiaPha.dc.html`. Spec:
`Docs/Specs/FamilyTree/requirements.md`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILFamilyTreeEntity.swift`, `ILFamilyChronicleEntity.swift` | Done | `ILFamilyTreeEntity` (id, side nội/ngoại, chronicle), `ILFamilyMemberEntity` (name, gender, birth/death year, lunar anniversary, note, parent, spouse, clan head, residence, burial, dharma name, tablet temple). |
| Presentation — StateModel | `ILFamilyTreeStateModel.swift` | Done | Layout, node display models, chips, search, selection/lineage/alphas, detail sheet model, focus request, switcher rows (`ILFamilyTreeViewKind`), merged-view flag. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | Not generated; see `AS-FamilyTree-001`. |
| Domain — UseCase | `ILFamilyTreeUseCase.swift`, `ILFamilyTreeGraph.swift`, `ILFamilyTreePedigree.swift` | Partial | `ILFamilyTreeGraph` (generations, lineage, branch, relations, search) and `ILFamilyTreePedigree` (the merged "Nội – ngoại" tree: viewer's ancestors on both sides) are real and tested. `loadTrees()` is a stub returning no books (`TD-FamilyTree-001`, `TD-FamilyTree-011`). |
| Presentation — Layout | `ILFamilyTreeLayout.swift` | Done | Pure tidy-tree geometry: positions, branch curves, spouse links, leaves. |
| Presentation — ViewModel | `ILFamilyTreeViewModel.swift` | Done | 25 input triggers; keeps the user's books in memory (`TD-FamilyTree-011`), switches between a book and the merged view, hands updated books back from the profile / chronicle / add-member screens. |
| Presentation — ViewController | `ILFamilyTreeViewController.swift` + `Views/` (incl. `ILFamilyTreeEmptyView`, `ILFamilyTreeSwitcherView`) | Done (not run on device) | Built from tokens (`ILColors.FamilyTree`, `ILTypography.tree*`, `ILMetrics.FamilyTree`); not yet seen on a device. |
| Presentation — Coordinator | `ILFamilyTreeCoordinator.swift` | Done | `.back`, `.createTree`, `.addMember`, `.openProfile` (→ `FamilyTreeMember`), `.openChronicle` (→ `FamilyTreeChronicle`) wired. |
| Tests | `ILFamilyTreeViewModelTests.swift`, `ILFamilyTreeGraphTests.swift`, `ILFamilyTreeLayoutTests.swift`, `ILFamilyTreePedigreeTests.swift` | Written, not executed | Type-checked with `swiftc` against the built module; XCTest needs a simulator / signed device. The pedigree rules were additionally run natively on macOS. |
| Wiring | `DIContainer` + `ILMemorialCoordinator` | Done | Section coordinator parent: Memorial. |

## Navigation events

`ILFamilyTreeNavEvent`:
- `.back` — pop and `finish()`.
- `.createTree` — push the `FamilyTreeCreate` child flow (`ILFamilyTreeCreateCoordinator`); its delegate hands the new tree back.
- `.addMember`, `.addDescendant` — push the `FamilyTreeAddMember` child flow (not offered in the merged view).
- `.openProfile(memberID:)` — push the `FamilyTreeMember` child flow (view + edit); the coordinator asks the ViewModel for the member's own book and kinship (`profileContext`) and applies the saved book (`showUpdatedBook`).
- `.openChronicle` — push the `FamilyTreeChronicle` child flow with every book (`chronicleContext`); updates come back through `showUpdatedBooks`, "open this person" through `openMember`.
- `.remindAnniversary`, `.lightLamp`, `.chant`, `.openTemple` — detail-sheet actions; the coordinator handles each with a one-line `print("TODO: ...")` stub (`TD-FamilyTree-005`, `006`, `008`).

## Known gaps / not implemented yet

- `loadTrees()` has no data source, so on a device the screen shows its empty state until the user creates a book; books, edits and chronicles live in memory only — `TD-FamilyTree-001`, `TD-FamilyTree-011`.
- Empty state button "Tham gia bằng mã mời" is wired to a TODO stub (no destination flow) — `TD-FamilyTree-002`. "Tạo gia phả mới" opens `FamilyTreeCreate` (see its README); the tree it returns is shown via `showCreatedTree(_:)` but not persisted — `TD-FamilyTreeCreate-001`.
- The contextual pill's reminder, the TƯỞNG NIỆM pill/tiles and the temple link are built as UI but wired to TODO stubs — `TD-FamilyTree-005`, `006`, `008`. Residence / burial / dharma name / tablet temple rows always read "Chưa cập nhật" (no data source) — `TD-FamilyTree-009`.
- The "BẠN" viewer uses a placeholder resolver (TD-FamilyTree-010). A user has at most two books, the first paternal and the second maternal (`AS-FamilyTree-010`); in the merged view the mother's family is matched by name (`AS-FamilyTree-011`) and the two sides are not colour-coded (`TD-FamilyTree-012`).
- The serif face is Lora, not Cormorant Garamond — `TD-FamilyTree-003`.
- The design's other four bottom tabs (Thời gian, Ngày giỗ, Tư liệu, Thành viên) are out of scope.
- No UI test — not requested.

## Changelog

- 2026-10-04 — v2.2: book switcher menu (▾ on the clan name, nội / ngoại / merged "Nội – ngoại của bạn", chronicle link, "Tạo gia phả mới"); 譜 seal opens the chronicle; "Hồ sơ đầy đủ" opens the member profile. Fixes: zoom buttons no longer sit on a square white block (the root glyph is a shape layer, not `draw(_:)`), and the tree is centred against the up-to-date canvas height (header chips / legend appearing used to leave it too low).
- 2026-10-03 — v2.0 design parity (Phases 2, 3, 5): `ILFamilyTreeHeaderView`, tree-palette chips/search field, paper background (`ILFamilyTreePaperView`), wrapping legend, DỨT NHÁNH marker, gradient medallion, halo labels, detail-sheet extras.
- 2026-10-03 — "Tạo gia phả mới" now opens `FamilyTreeCreate` (`.createTree` nav event, `showCreatedTree(_:)`).
- 2026-10-03 — empty state rebuilt from the "Gia phả · trống" prototype screen (`ILFamilyTreeEmptyView`, `createTapped`/`joinTapped` inputs).
- 2026-10-03 — initial build from the "Gia Pha Mobile" design via ui-builder.
