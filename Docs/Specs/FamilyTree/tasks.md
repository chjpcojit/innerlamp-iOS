# Tasks — FamilyTree

Version: 2.2
Last updated: 2026-10-04
Status: v1.2 done; v2.0 Phases 2–6 implemented (build-verified, not run on device); Phase 7 partly pending

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — v1.2 (implemented)
- [x] Coordinator, ViewModel, StateModel, ViewController, canvas, node, medallion, legend, zoom controls, detail sheet, empty state
- [x] Link from Sổ giỗ "Xem gia phả" and create-form hand-off

## Phase 2 — Header & chips (design: Header, Generation chips)
- [x] Add `ILFamilyTreeHeaderView` (seal, serif title, subtitle, search + "+" buttons); remove `headerDivider`
- [x] Tree-palette generation chip; tree-palette search field with "{n} người" count
- [x] "+" wired to coordinator TODO stub + `TD-FamilyTree-` entry

## Phase 3 — Canvas, legend, markers (design: Canvas, Legend, Node/Medallion)
- [x] Paper gradient, dot grain, green blob, canvas top border
- [x] Wrapping legend with gradient founder hexagon (6 items; BẠN item shown when a viewer exists)
- [x] `isBranchEnd` in node model + "— DỨT NHÁNH —" marker + sheet "Chi" text
- [x] Branch width entry for generation 7
- [x] Medallion gradients, 4 garment tokens, hair stripes, collar notch, double-ring seal, tick ring
- [x] Name halo (stacked shadows) and selected-name colour

## Phase 4 — Viewer ("BẠN") (placeholder resolver — TD-FamilyTree-010)
- [x] `isMe` in node model, BẠN pill, legend item, gold zoom button, "Với bạn" row
- [x] Viewer resolver seam (`ILFamilyTreeViewerResolving`) + placeholder; tests for `isMe`, hidden-without-me, kinship (written, not executed)

## Phase 5 — Detail sheet
- [x] Extra fact rows (residence, burial, dharma name, tablet temple link)
- [x] TƯỞNG NIỆM card (deceased only) with pill button and 2 tiles
- [x] Bottom CTA row (contextual second pill)
- [x] Sheet header polish (grabber, chevron, top highlight)
- [x] New strings in `vi.json`; tokens in `ILColors`/`ILMetrics`

## Phase 6 — Clan switcher (unblocked 2026-10-04: "Danh sách cây + gộp")
- [x] `ILFamilyTreeSwitcherView` menu + ▾ on the header title; header seal / title taps
- [x] Several books in the ViewModel (`books`, `ILFamilyTreeViewKind`); `side` on the entity; "Tạo gia phả mới" row (paternal first, then maternal)
- [x] Merged "Nội – ngoại của bạn" view: `ILFamilyTreePedigree` (synthetic upside-down tree), merged labels / chips / detail / legend, no "+"
- [x] Chronicle ("Phả ký dòng họ") reachable from the seal and the menu — spec `Docs/Specs/FamilyTreeChronicle/`
- [x] Member profile + edit reachable from "Hồ sơ đầy đủ" — spec `Docs/Specs/FamilyTreeMember/`
- [ ] Colour the two sides in the merged view — `TD-FamilyTree-012`

## Phase 6b — Fixes (2026-10-04)
- [x] Zoom buttons: no square block behind the rounded corners (root glyph as a shape layer)
- [x] Tree centred against the current canvas height (layout before centring; re-centre on canvas resize until the user moves it)

## Phase 7 — Verification & records
- [x] Update `ILFamilyTreeViewModelTests` for new model fields (isBranchEnd, extras, memorial, stub events; written, not executed — no simulator)
- [x] Tech-debt entries (bilingual) for every TODO stub; assumption entries for unconfirmed items (Phases 2, 3, 5: TD-FamilyTree-004…009, AS-FamilyTree-006…008; Phase 4: TD-FamilyTree-010, AS-FamilyTree-009; Phase 6: TD-FamilyTree-011, 012, AS-FamilyTree-010, 011)
- [x] `xcodebuild build` (generic/platform=iOS) passes (passed after Phases 2–6)
