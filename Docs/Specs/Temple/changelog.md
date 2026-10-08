# Changelog — Temple Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v2.5.2 — Hero shows temple photo (2026-10-06)

Code-only entry; no requirement/design prose change.

- Detail hero now shows the server `image_url` (already carried in `ILTempleSummaryEntity.imageURL`)
  at the top of the hero via `ILRemoteImageView`: full width, fixed 220pt height, `scaleAspectFill`
  (edge to edge, overflow cropped); the title block sits below it. A temple with no
  image gets height 0, i.e. the previous gradient-only hero. `ILTempleStateModel.heroImageURL` added.

## v2.5.1 — Dev backend host moved (2026-09-30)

Config-only entry; no spec prose change.

- `APIConfig.dev` moved to `172.16.15.119:8080` (LAN IP of the Mac running the backend) and the
  `Info.plist` ATS exception domain moved with it. `192.168.1.124` no longer accepted TCP
  connections, so every catalog request hung for the full 30 s request timeout before falling
  back to cache — the "temples / deities load slowly" report. The backend itself answers every
  catalog route in ~2–50 ms.

## v2.5 — Editorial content from API contract v1.1 (2026-09-30)

Implementation entry. Backend contract v1.1 (`docs/specs/features/temple/api-contract.md` in the
backend repo) adds three fields to `GET /v1/temples/{id}` only (top/list unchanged):
`introduction: string`, `architecture_heritage: string`, `visiting_notes: [string]` — never
`null`, `""` / `[]` when missing. `requirements.md` / `design.md` prose not yet refreshed (to be
done by `il-spec-writer`).

- Data: `ILTempleDetailDTO` gains the three fields as optionals so a detail cached before v1.1
  still decodes for the offline fallback; `ILTempleMapper` maps `nil` → empty, trims text and
  drops blank notes. `ILTempleDetailEntity` gains `introduction`, `architectureHeritage`,
  `visitingNotes`.
- Presentation: "Giới thiệu" ← `introduction` (existing collapsible biography), "Kiến trúc &
  di sản" ← `architecture_heritage` as one multi-line paragraph (state `archStyle` + `materials`
  replaced by `architectureText`; highlight cards stay empty), "Lưu ý khi viếng thăm" ←
  `visiting_notes` numbered "01", "02"…. Empty content keeps the v2.4 "Đang cập nhật"
  placeholder (the section is not hidden).
- Backend also removed `temple_central_022` (now 404 `TEMPLE_NOT_FOUND`, 179 temples); no app
  fixture/mock referenced it.
- Tests: fixture updated to the v1.1 shape (v1.0 kept as `templeDetailV1_0`); new repository
  test for v1.0 payload/cache compatibility; ViewModel tests cover filled and empty content.

## v2.4 — Full UI restored; only API data is filled (2026-09-30)

Implementation entry. Reverts the UI removal of v2.3 at the user's request ("không xoá giao
diện, chỉ không fill dữ liệu nếu không có").

- Every design section is back and always visible: status card (incl. distance slot and the
  weekday + Rằm/Mùng Một rows), biography (+ "Đọc thêm"), org info, architecture & highlights,
  amenities, visit rules, events & sessions, location & contacts, footer. All inputs / nav
  events (`bioToggled`, `eventsTapped`, `sessionTapped`, `contactTapped`, `.events`,
  `.session`) are restored.
- Data rule: only fields from `GET /v1/temples/{id}` are filled. Anything else is left empty and
  rendered as the design's "Đang cập nhật" placeholder: biography, architecture, visit rules,
  holiday hours, "Giáo hội", "Kinh sách" amenity, the 4 contact rows. Events shows its empty
  state; the distance slot stays blank (no real user location); the footer shows only "Báo
  thông tin sai" when there is no "updated" date.
- API `operating_hours` fills the "Ngày thường" row and drives the open/closed status.
- Localization keys restored; added `temple.org.sangha`, `temple.amenity.books`,
  `temple.contact.*`.

## v2.3 — Server data only; non-API sections removed (2026-09-30) — superseded by v2.4

Implementation entry, at the user's request ("xoá mock trang chùa và chỉ sử dụng từ API
server"). `requirements.md` / `design.md` prose still describes the full design — to be
refreshed by `il-spec-writer`.

- Removed (not just hidden) every section the API does not supply: biography, architecture &
  highlights, visit rules, events & sessions (incl. the empty state and "Xem tất cả"),
  contacts, and the "Cập nhật …" footer part. Removed their state fields/models, the
  `bioToggled` / `eventsTapped` / `sessionTapped` / `contactTapped` inputs, and the
  `.events` / `.session` nav events.
- Removed the "Cách bạn X km" distance: it was computed from a hard-coded user location (fake
  data). It comes back once real location permission exists.
- Screen now shows: hero, follow/directions/offer buttons, open status + daily hours, facts
  grid, org info, amenities, location (address, region, coordinates, Google/Apple Maps), and
  the "Báo thông tin sai" footer label (static copy, no data).
- Dropped the now-unused `temple.*` localization keys from `vi.json`.

## v2.2 — Detail screen wired to `GET /v1/temples/{id}` (2026-09-30)

Implementation entry. `requirements.md` / `design.md` prose is unchanged (both still describe
the static catalog — to be refreshed by `il-spec-writer`); Phase 3 task checkboxes updated.

- `ILTempleUseCase.getInitialState(templeID:)` (static 9-temple catalog) replaced by
  `loadTemple(id:) async throws -> ILTempleDetailEntity`, backed by
  `ILTempleRepository.loadTempleDetail(id:)` (network-first, Core Data fallback). The mock
  `ILTempleEntity` (+ opening-hours/org/amenity/contact/session entities) is deleted; the
  session tone/glyph enums moved into `ILTempleStateModel.swift`.
- `ILTempleViewModel`: `.idle → .loading → .success/.failure`; new `retryTapped` input; new
  `Output.errorMessage` for transient errors (follow failure now reverts + toasts instead of
  replacing the screen with `.failure`).
- `ILTempleViewController`: full-screen loading (`ILLoadingDotsView`) and error
  (`ILStateView` `.error`/`.offline` + retry `ILButton`) states; sections with no data are
  hidden.
- Rank / region / sect labels shared with Home through `ILTempleCatalogLabels`
  (`Presentation/Common/Formatting/`).
- Decisions / assumptions:
  - The API detail is much thinner than the design's `TEMPLE_INFO`. Shown from the server:
    name, aliases, heritage rank, sect, region, founding year, address + coordinates, current
    abbot, founder, operating hours, 4 amenity booleans. **Hidden** (no API field): biography,
    architecture & highlights, visit rules, contacts, "Cập nhật …" footer part. The events
    section always shows its empty state (no schedule API). UI code for the hidden sections is
    kept so they reappear once the API adds the fields.
  - `operating_hours` is parsed as `"HH:mm - HH:mm"` (one daily range; no Rằm/Mùng Một
    holiday range any more). Empty/unparseable → "Chưa rõ giờ mở cửa" + "Đang cập nhật".
  - Empty `founder` / `current_abbot` (common on the dev server) → "Đang cập nhật".
  - `sect` is a raw server string; known values (matched ignoring diacritics) get a localized
    label, unknown ones are humanized ("TỊNH_ĐỘ_TÔNG" → "Tịnh độ tông").
  - `.notFound` / other errors show the generic error state; `.offline` shows the offline
    variant. Both offer retry.
  - Distance still uses the fixed user location (no location permission yet).
  - `ILSanghaCoordinator` still opens this screen with mock community ids (not server temple
    ids), so from Sangha it currently shows the "not found" error state.

## v2.1 — Data layer: temple + Buddha/Bodhisattva catalog API with Core Data cache (2026-09-29)

Implementation entry. `requirements.md` / `design.md` prose is unchanged; Phase 3 task
checkboxes updated. Presentation still reads the mock catalog — wiring the screens is a
follow-up.

- Contract (confirmed by BE-Developer, verified with curl against the dev server): public GET
  `/v1/temples/top`, `/v1/temples?page=N`, `/v1/temples/{id}`, `/v1/deities/top`,
  `/v1/bodhisattvas?page=N`, `/v1/deities/{id}`. Page-number paging, 1-based, fixed server
  page size 20; end of list = `page >= total_pages` or empty `items`.
- Added: `ILTempleRepository` / `ILDeityCatalogRepository` (Domain), their `*Impl`, DTOs,
  `ILTempleMapper`, 6 endpoints, `ILTempleLocalDataSource` / `ILDeityCatalogLocalDataSource`,
  shared `ILCatalogCache`, `ILCatalogError`; registered in `DIContainer`.
- Core Data model v2 (`InnerLamp 2.xcdatamodel`, now current): adds `CachedTemple`,
  `CachedDeity`, `CatalogListState`. v1 is kept so existing stores migrate (lightweight,
  additive only).
- Decisions / assumptions:
  - "Show all" lists are local-first: a cached page is served with no network call; when
    local runs out the server is asked, new rows are stored, and an empty server page (or the
    last page) ends the list. Top and detail are network-first with a cached fallback when
    offline; a server `*_NOT_FOUND` is never masked by the cache.
  - A change in the server's `total` resets the cached list layout (positions would no longer
    line up with server pages); pages are refetched on demand. Callers should de-duplicate by
    `id` when appending pages, since server-side inserts can shift rows across page boundaries.
  - Temple `type` / `region` / `heritage_rank` are open enums (`.other(raw)`), per the BE
    advice. Deity `type` stays closed (`ILDeityKind` is switched exhaustively in the UI): an
    unknown value fails decoding.
  - The server deity catalog lives in its own entity (`CachedDeity`), separate from the bundled
    `phat_botat.json` store (`Deity`), which still backs the lunar-date / search queries. Same ids.
  - Image URLs are stored raw; they do not resolve yet (BE caveat), so the UI must use a
    placeholder.
  - `APIConfig.dev` moved to `192.168.1.124:8080` (the old `.113` no longer answers).

## v2.0 — full redesign to match `Component.TEMPLE_INFO`

- Rebuilt the Temple detail screen to match the complete design handoff
  (`isTemple` in `InnerLamp Prototype.dc.html`), which the v1.0 spec/code only
  partially implemented (a simplified 3-stat strip instead of the real status
  card + facts grid, no org info / architecture / amenities / visit rules /
  location & contacts sections).
- `requirements.md`: rewrote the acceptance criteria to cover every section of
  the redesigned screen (hero chips + alias, 3 buttons, status card, facts
  grid, collapsible biography, org info, architecture + highlights, amenities,
  visit rules, sessions incl. empty state, location & contacts, footer) and
  their new interactions (`.openURL` for Maps/contacts). Added one resolved
  open question about the two different "no rank" fallback strings.
- `design.md`: rewrote the Layers & components table for the expanded
  `ILTempleEntity`/`ILTempleStateModel` shape, documented the client-side
  open/closed + distance computation (`ILLunarCalendar` + haversine) in Data
  flow, added `.openURL` to the navigation flow, and recorded the removal of
  `ILTempleStatsView` in favor of `ILTempleStatusCardView` + the facts grid.
- `tasks.md`: Phase 1–2 items updated/annotated for the v2 scope (all still
  `[x]`, now 11 tests instead of 6); Phase 4 gained a completed "wire
  Google/Apple Maps + contact URLs" item; Phase 5's OKF item is now done.
- Reason: the user asked to update the Temple screen to match the new design;
  the design handoff's `TEMPLE_INFO` data model turned out to be substantially
  richer than what v1.0 had speced/shipped, so both the spec and the
  implementation needed a full pass rather than an incremental patch.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Temple feature
  (the detail screen only; the discovery/list scope in `SRS.md` is not built).
- `requirements.md`: user story and 6 EARS acceptance criteria (load name +
  subtitle + stats + description + sessions + address, follow toggle, offer
  event, directions event, session event, back). "Pending" records the static
  catalog (with a ⚠️ on the temple API), the `toggleFollow` stub, the three TODO
  destinations, and the absent loading/error states. One resolved open question
  (only the detail screen shipped; the discovery feature is separate). Notes
  `SRS.md` as an upstream BA document describing a larger scope.
- `design.md`: Layers & components table (Entity + session/tone/glyph, UseCase,
  StateModel, ViewModel, leaf Coordinator, ViewController, 2 feature views,
  shared tokens), navigation flow (from Home + Sangha), data flow, and a
  "Deliberately stub / mock" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 6
  tests; Phase 3 (temple API) pending on contract; Phase 4 (sub-destinations)
  pending; a "Deferred" section records the discovery/list scope from `SRS.md`
  as a separate future feature.
- Reason: Temple had only an upstream `SRS.md`; written the 3-file convention
  retroactively to document what actually shipped (the detail screen), while
  keeping `SRS.md` as the BA source.
