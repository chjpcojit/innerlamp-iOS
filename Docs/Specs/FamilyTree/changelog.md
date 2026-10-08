# Changelog — FamilyTree spec

## 2.2 — 2026-10-04
- Clan switcher ⚠️ resolved ("Danh sách cây + gộp"): a user has up to two books (father's "nội", mother's "ngoại"), a merged "Nội – ngoại của bạn" view, and the header's clan name opens a menu listing them plus the "Phả ký dòng họ" link and "Tạo gia phả mới". The red 譜 seal also opens the chronicle. "Phả ký" overlay and view-mode tabs moved from Out of scope into scope (own specs: `FamilyTreeChronicle`, `FamilyTreeMember`). New records: AS-FamilyTree-010, 011; TD-FamilyTree-011, 012; TD-FamilyTree-007 resolved.
- Requirement text added for the zoom buttons' rounded look and for centring the tree vertically (bug fixes, not scope).

## 2.1 — 2026-10-03
- "Me" id ⚠️ resolved (moved to Open questions (resolved) in `requirements.md`): the viewer will be matched from the signed-in account by name / phone number; a placeholder resolver (clan head) is used now. Requirement text added for hiding every BẠN element without a viewer and for deriving "Với bạn" from the tree (hidden when not derivable).
- `design.md`: viewer resolver seam, kinship rules, gold tokens/icon. `tasks.md`: Phase 4 ticked (implemented, build-verified; unit tests written but not executed). New records: TD-FamilyTree-010, AS-FamilyTree-009.

## Implementation note — 2026-10-03
- Phases 2, 3 and 5 of `tasks.md` implemented (header, tree-palette chips/search, canvas paper/grain/blob/top border, wrapping legend, DỨT NHÁNH, G7 branch width, medallion visuals, name halo, detail-sheet extras). No requirement or design text changed. BẠN/me (Phase 4) and clan switcher (Phase 6) not built. TODO stubs tracked in `Docs/Tech-Debt/FamilyTree/` (TD-004…009); new assumptions AS-006…008.

## 2.0 — 2026-10-03
- Re-based on `Docs/InnerLamp project/IL-GiaPha.dc.html`. Scope change: header with seal/search/"+", clan switcher, tree-palette chips, 6-item wrapping legend, BẠN badge + "me" zoom button, DỨT NHÁNH marker, medallion/label/canvas visual parity, richer detail sheet (extra facts, TƯỞNG NIỆM, bottom CTAs) moved into scope; "Phả ký" overlay and view-mode tabs kept out (⚠️ unconfirmed).
- `design.md` and `tasks.md` created (retroactive for v1.2, prospective for v2.0). All v2.0 tasks `[ ]`.
- Open ⚠️ items: multi-clan switcher, add-member flow, "me" id, extra member fields, offering/reminder/profile destinations, Cormorant Garamond font.

## 1.2 — 2026-10-03
- "Tạo gia phả mới" now opens the create form (`Docs/Specs/FamilyTreeCreate/`); only "Tham gia bằng mã mời" remains a TODO stub.

## 1.1 — 2026-10-03
- Empty state specified from the "Gia phả · trống" prototype screen (illustration, steps card, create/join buttons, footnote).

## 1.0 — 2026-10-03
- Initial spec, written from the "Gia Pha Mobile" prototype when the screen was built.
