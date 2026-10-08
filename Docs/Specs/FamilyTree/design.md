# Design — FamilyTree

Version: 2.2
Last updated: 2026-10-04
Status: v1.2 layers and v2.0 design parity implemented; v2.2 adds books, switcher, merged view (build-verified, not run on device)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

UIKit, MVVM-C. Folder `InnerLamp/Presentation/Scenes/FamilyTree/`. No network call yet (no data
source; screen shows its empty state), so no Step-by-step Flow section is required. All colours,
fonts and metrics come from `ILColors.FamilyTree` / `ILTypography` / `ILMetrics` tokens; new values
are added to the token files, never inlined. Design source: `Docs/InnerLamp project/IL-GiaPha.dc.html`.

## Layers & components

| Component | File | v2.0 change |
|---|---|---|
| Coordinator | `ILFamilyTreeCoordinator.swift` | Route "+", "Hồ sơ đầy đủ", reminder/offering/chant tiles, temple link as TODO stubs |
| ViewModel / StateModel | `ILFamilyTreeViewModel.swift`, `ILFamilyTreeStateModel.swift` | Add `isBranchEnd`, `isMe`, extra member facts (residence, burial place, dharma name, tablet temple); `meID` (resolved through `ILFamilyTreeViewerResolving`, one injected seam; placeholder = clan head — TD-FamilyTree-010), `meTapped` input, `kinship` in the detail model |
| ViewController | `ILFamilyTreeViewController.swift` | Replace `ILNavBar` + divider with the new header; tree-palette chips; canvas top border |
| Header (new) | `Views/ILFamilyTreeHeaderView.swift` | Seal 34×34 (-4°), serif clan name 25, ▾ when `canSwitch`, subtitle 11, 44pt search and "+" buttons |
| Generation chips | `ILChip` tree variant, or `Views/ILFamilyTreeChipView.swift` | Tree palette (`Tree.brown`/`Tree.bark`/cream); 34pt high, 12/medium |
| Canvas | `Views/ILFamilyTreeCanvasView.swift` | Paper gradient (600×500 radius), dot grain layer, green blob; branch width entry for G7 = 2.6 |
| Node / Medallion | `Views/ILFamilyTreeNodeView.swift`, `Views/ILFamilyTreeMedallionView.swift` | Gradient trims/plates/ticks, 4 garment tokens, hair stripes, collar notch, double-ring seal, name halo (stacked shadows), BẠN pill, DỨT NHÁNH marker |
| Legend | `Views/ILFamilyTreeLegendView.swift` | Wrapping flow layout, 6 items, gradient founder hexagon, padding 20 |
| Zoom controls | `Views/ILFamilyTreeZoomControlsView.swift` | Fourth gold "me" button (hidden when no viewer is resolved); tighter shadow |
| Detail sheet | `Views/ILFamilyTreeDetailSheetView.swift` | "Với bạn", extra fact rows, TƯỞNG NIỆM card, bottom CTA row; header polish (grabber 36×4, chevron stroke 2.2) |
| Formatter / Layout | `ILFamilyTreeFormatter.swift`, `ILFamilyTreeLayout.swift` | Strings for new rows; generation-gap check at 7 generations |
| Tokens & strings | `ILColors.swift` (FamilyTree), `vi.json` | New gradient/garment/gold tokens; strings listed in requirements v2.0 |

## Decisions

- Layout stays the generic recursive layout (`Layout.swift`), not the prototype's hand-tuned per-member coordinates; generation gap difference is intentional.
- The serif face stays `Lora` (design system substitution for Cormorant Garamond). > ⚠️ Not confirmed: should the Cormorant Garamond font be bundled? — affects node-label and header widths.
- Gradients are `CAGradientLayer`s masked by the hexagon path; the 72-tick conic ring is drawn as alternating arc segments.
- Viewer ("BẠN"): `ILFamilyTreeViewerResolving.viewerMemberID(in:)` is the single seam the ViewModel asks; the only implementation is `ILPlaceholderFamilyTreeViewerResolver` (clan head) until account name/phone matching exists. "Với bạn" comes from `ILFamilyTreeGraph.kinship(of:relativeTo:)` (self, ancestors, descendants, siblings, spouse; `nil` → row hidden). Gold values are tokens (`ILColors.FamilyTree.me`/`inkOnMe`), the zoom glyph is `ILIcons.personViewer`.
- Items marked ⚠️ in requirements v2.0 (switcher, "+", "me", extra facts, offering tiles, CTAs) ship as UI wired to TODO stubs; each gets an entry in `Docs/Tech-Debt/FamilyTree/`.

## v2.2 — Books, switcher, merged view, centring (2026-10-04)

**Books.** `ILFamilyTreeEntity` gained `id`, `side` (`ILFamilyTreeSide`: `.paternal` / `.maternal`) and `chronicle`. `ILFamilyTreeViewModel` keeps `books: [ILFamilyTreeEntity]` in memory and shows one of them (`ILFamilyTreeViewKind.book(id)`) or the merged tree (`.merged`). `ILFamilyTreeUseCase.loadTrees()` replaces `loadTree()` (still a stub). The first book a user creates is paternal, the second maternal (`AS-FamilyTree-010`).

**Switcher.** `ILFamilyTreeSwitcherView` (scrim + paper card, pinned under the header) is driven by `ILFamilyTreeStateModel.switcherRows`, `isSwitcherOpen`, `canCreateBook`. Inputs: `titleTapped`, `switcherDismissed`, `viewSelected`, `chronicleTapped`; "Tạo gia phả mới" reuses `createTapped`. The header (`ILFamilyTreeHeaderView`) exposes `onSeal`, `onTitle`, `showsSwitcher`, `showsAdd`.

**Merged view.** `ILFamilyTreePedigree.build(viewerID:paternal:maternal:)` turns the viewer's ancestors into an ordinary `ILFamilyTreeEntity` turned upside down — the viewer is the root and each person's father and mother are that person's two children — so `ILFamilyTreeGraph`, `ILFamilyTreeLayout` and the canvas need no special case. Ids are tagged (`n:` paternal book, `g:` maternal book) and `origins` maps them back to `(treeID, memberID, side, depth)`. The viewer's mother is looked up in the maternal book by name (`AS-FamilyTree-011`). In merged mode the ViewModel swaps node meta, chip titles, detail meta / relations / lineage title / contextual pill for the pedigree texts, never marks a branch end, and the legend shows only "BẠN" and "Còn sống".

**Hand-offs.** `profileContext(memberID:)` (the member's own book, id and kinship), `chronicleContext()`, `showUpdatedBook`, `showUpdatedBooks`, `openMember(treeID:memberID:)`, `showCreatedTree`.

**Centring.** `ILFamilyTreeViewController.updateUI` lays the view out before centring (the chips / legend / search field change the canvas height), `applyPendingFocus` refreshes the insets first, and `recenterIfCanvasResized` re-centres when the canvas height changes until the user pans or zooms (`userHasMovedCanvas`). **Zoom buttons:** `ControlButton` no longer overrides `draw(_:)`; the root glyph is a `CAShapeLayer`.

