# Requirements — FamilyTree

Version: 2.2
Last updated: 2026-10-04
Status: v2.2 — clan switcher, merged view, chronicle and member profile implemented (build-verified, not run on device); v2.1 — BẠN viewer UI implemented with a placeholder resolver; v1.2 behavior implemented (build-verified; UI not run on device); v2.0 design-parity items pending — no data source yet, screen shows its empty state

> See `changelog.md` in this folder for the version history of this spec.
Feature folder: `InnerLamp/Presentation/Scenes/FamilyTree/`

> Source of truth (v2.0): `Docs/InnerLamp project/IL-GiaPha.dc.html` (tree view mode; supersedes `Docs/InnerLamp icon consistency/Gia Pha Mobile.dc.html`); entry rows and empty state: `Docs/InnerLamp project/InnerLamp Prototype.dc.html`; earlier empty-state reference: `Docs/InnerLamp icon consistency/InnerLamp Prototype.dc.html` (screen "Gia phả · trống", `isGiaPhaEmpty`).

## User Story

As a member of a clan, I want to see my family as a tree, so that I can find any relative, see how we
are related, and trace a person's line back to the founder.

## Acceptance Criteria (EARS notation)

- WHEN the user taps "Xem gia phả" on the Sổ giỗ chạp list, THE SYSTEM SHALL open the family tree.
- WHEN the tree loads, THE SYSTEM SHALL draw the founder at the bottom, each later generation one
  row higher, every person as a hexagon medallion with their short name and generation caption,
  and spouses beside their partner joined by a dashed line.
- WHEN the tree loads and has a clan head, THE SYSTEM SHALL select and centre the clan head;
  otherwise the founder.
- WHEN the user taps a person, THE SYSTEM SHALL select them, highlight the line from the founder to
  them in gold, centre them, and show their summary in the bottom sheet.
- WHEN the user taps the sheet header, THE SYSTEM SHALL expand it to show lifespan, lunar death
  anniversary, branch, note, relations and the lineage from the founder; tapping the dimmed area
  SHALL collapse it; tapping a relation or lineage row SHALL select that person and collapse it.
- WHEN the user picks a generation chip, THE SYSTEM SHALL dim everyone not in that generation.
- WHEN the user opens search and types, THE SYSTEM SHALL dim non-matching people (ignoring case and
  diacritics), show the match count, and on Return select the first match.
- WHEN the user taps zoom +/−, THE SYSTEM SHALL step through 0.7× / 1× / 1.35×; pinch SHALL also zoom.
- WHEN the user taps the root button, THE SYSTEM SHALL clear the generation filter and search and
  select the founder.
- IF there are no members, THEN THE SYSTEM SHALL show an empty state instead of the canvas: header subtitle "Chưa có gia phả", sapling illustration, title, message, a 3-step card (dựng cây nhiều đời / giữ ngày giỗ / viết phả ký), the buttons "Tạo gia phả mới" and "Tham gia bằng mã mời", and an invite footnote.
- WHEN the user taps "Tạo gia phả mới", THE SYSTEM SHALL open the create form (spec: `Docs/Specs/FamilyTreeCreate/requirements.md`) and, once a tree is created, show it in place of the empty state.
- WHEN the user taps "Tham gia bằng mã mời", THE SYSTEM SHALL start the join flow — not built yet, the button is wired to a TODO stub (`TD-FamilyTree-002`).

### Added in v2.0 (design parity with `IL-GiaPha.dc.html`)

**Header & filters**
- WHEN the tree screen is shown, THE SYSTEM SHALL show a header with a red seal "譜", the clan name left-aligned in the serif face, the subtitle "{quê} · {n} đời · {m} người", a round search button and a round "+" button, and no divider below the header.
- WHEN the tree screen shows a book, THE SYSTEM SHALL show a ▾ next to the clan name; WHEN the user taps the clan name, THE SYSTEM SHALL open a menu "GIA PHẢ CỦA BẠN" listing each of the user's books (seal, name, "Bên nội / Bên ngoại · quê · n đời · m người", a check on the current one), then — only when a paternal and a maternal book exist and the viewer is in the paternal book — "Nội – ngoại của bạn", a divider, "Phả ký dòng họ" and, while the user has fewer than two books, "Tạo gia phả mới". Tapping outside the menu closes it.
  > Resolved 2026-10-04 ("Danh sách cây + gộp"): the user has at most two books, the first created is the paternal one, the second the maternal one (`AS-FamilyTree-010`); books are kept in memory only (`TD-FamilyTree-011`).
- WHEN the user picks a book, THE SYSTEM SHALL draw that book and open on its clan head (else the founder).
- WHEN the user picks "Nội – ngoại của bạn", THE SYSTEM SHALL draw the viewer's ancestors on both sides as one tree with the viewer at the trunk, the father's line on the left and the mother's on the right; rows are named "Bạn / Cha mẹ / Ông bà / Cụ / Kỵ / Tổ", node labels read the kin ("CHA", "MẸ", "ÔNG NỘI", "BÀ NGOẠI"), the detail sheet reads "ĐƯỜNG NỐI VỚI BẠN", the contextual pill reads "Mở trong họ …" ("Hồ sơ của bạn" for the viewer) and "+" is hidden. The mother's own family is taken from the maternal book by matching her name (`AS-FamilyTree-011`); the two sides are not colour-coded (`TD-FamilyTree-012`).
- WHEN the user taps the red 譜 seal or "Phả ký dòng họ" in the menu, THE SYSTEM SHALL open the clan chronicle (spec: `Docs/Specs/FamilyTreeChronicle/requirements.md`).
- WHEN the user taps "+", THE SYSTEM SHALL start adding a member.
  > ⚠️ Not confirmed: add-member flow (fields, relation picker, API) — "+" is wired to a TODO stub until confirmed.
- THE SYSTEM SHALL render the generation chips in the tree palette (selected: brown fill with cream text; unselected: translucent cream with brown text and border) in both light and dark mode.
- THE SYSTEM SHALL render the search field in the tree palette with a trailing "{n} người" count.

**Canvas**
- THE SYSTEM SHALL render the canvas on the paper radial gradient with a faint dotted paper grain and a soft green blob, with a 1px top border below the header.
- THE SYSTEM SHALL render clan-head and founder medallion trims, plates and tick rings with the design's gradients, garments by sex and living/deceased state (4 colours), the collar notch, and the double-ring clan-head seal.
- THE SYSTEM SHALL render each name with a soft cream halo so it stays legible over branches.
- WHEN a deceased member who is not a spouse, in generation > 1, has no children, THE SYSTEM SHALL show "— DỨT NHÁNH —" under their meta line, and "Chi" in the sheet SHALL read "Dứt nhánh · không có hậu duệ".
- THE SYSTEM SHALL draw branches for generation 7 and deeper with width 2.6.
- THE SYSTEM SHALL show the legend as a wrapping row: Thủy tổ (gold-gradient hexagon), BẠN badge, Tộc trưởng, Còn sống, Vợ chồng, Dứt nhánh.

**"BẠN" (viewer)**
- WHEN the signed-in user is a member of the tree, THE SYSTEM SHALL mark their node with a gold "BẠN" pill above it, add a gold fourth zoom button that selects and centres them, and show "Vị trí của bạn" in the legend; sheet relation text SHALL include "Với bạn".
  > Resolved 2026-10-03 (see Open questions (resolved)): the viewer is linked later by account name / phone; a placeholder resolver (the clan head) drives the UI until then. WHEN no viewer is resolved, THE SYSTEM SHALL hide the pill, the gold button, the legend item and the "Với bạn" row. "Với bạn" SHALL be derived from the tree (self, ancestors, descendants, siblings, spouse) and hidden when not derivable.

**Detail sheet (expanded)**
- THE SYSTEM SHALL show, in addition to v1.2 rows: "Với bạn" (accent colour, semibold), "Đang sống tại" (living; "Chưa cập nhật" when empty), "Nơi an táng", "Pháp danh" and "Bài vị thờ tại" (tappable, underlined, opens the temple).
  > ⚠️ Not confirmed: source/API fields for residence, burial place, dharma name, ancestral-tablet temple — rows render "Chưa cập nhật" until a data source exists.
- WHEN the selected member is deceased, THE SYSTEM SHALL show a "TƯỞNG NIỆM" card: round "忌" glyph, "Giỗ {ngày âm lịch}", subtitle with countdown and "giỗ lần thứ N", a pill button ("Nhắc giỗ hằng năm" / "✓ Đã có trong Sổ giỗ · Mở" / "Bổ sung ngày giỗ"), and a 2-column grid of "Thắp đèn · Cúng dường hồi hướng" and "Tụng kinh · Hồi hướng công đức" tiles.
  > ⚠️ Not confirmed: destinations/behavior of the reminder pill, "Thắp đèn" and "Tụng kinh" tiles (Bell/Reader/Memorial hand-off?) — tiles are wired to TODO stubs until confirmed.
- THE SYSTEM SHALL show two bottom pills: "Hồ sơ đầy đủ" (filled) and a contextual outlined pill ("Thêm con cháu" for the living, "Nhắc ngày giỗ" for the deceased).
- WHEN the user taps "Hồ sơ đầy đủ", THE SYSTEM SHALL open the member profile (view, then "Sửa" to edit; spec: `Docs/Specs/FamilyTreeMember/requirements.md`) and, after a save, show the changed person on the tree.
  > Resolved 2026-10-04: the profile screen exists (`TD-FamilyTree-007`). The "Thêm con cháu" pill opens the add-member form; "Nhắc ngày giỗ" stays a TODO stub (`TD-FamilyTree-005`).

**Zoom controls & centring (fixes, 2026-10-04)**
- THE SYSTEM SHALL draw each zoom / "me" / root button as a rounded square with its own border and shadow and nothing square behind it.
- WHEN a tree is shown, THE SYSTEM SHALL centre it vertically in the canvas area above the collapsed detail sheet using the canvas height after the header (chips, legend, search field) has been laid out, and SHALL re-centre when that height changes until the user pans or zooms.

## Out of Scope

- Persistence / API for the clan book (see `Docs/Tech-Debt/FamilyTree/`).
- Colouring the father's and mother's lines differently in the merged view (`TD-FamilyTree-012`).
- The design's other tabs (Thời gian, Ngày giỗ, Tư liệu, Thành viên).

## Open questions (resolved)

- ~~How does the app link the signed-in account to a tree member ("me" id)?~~ → Resolved 2026-10-03: the member is matched from the signed-in account by name or phone number against the tree's members (future rule, unvalidated — `Docs/Assumptions/FamilyTree/AS-FamilyTree-009-viewer-matched-by-name-or-phone.md`). Until that matching exists, a placeholder resolver (`ILPlaceholderFamilyTreeViewerResolver`, picks the clan head) supplies the "me" member — `Docs/Tech-Debt/FamilyTree/TD-FamilyTree-010-placeholder-viewer-resolver.md`.
