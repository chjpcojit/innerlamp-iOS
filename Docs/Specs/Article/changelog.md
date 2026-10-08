# Changelog — Article Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.3 — Hero image loaded from `image_url` (2026-10-06)

Implementation entry following a BE change: the articles API contract (routes,
schema, paging, errors, auth) is unchanged; only data changed — `image_url` was
`null` for 22 articles and now all 60 articles have an https URL.

- `requirements.md`: 2 EARS criteria (load cover into the hero with placeholder
  until loaded; keep placeholder when the image fails). Pending item rewritten:
  images are publisher hotlinks.
- `design.md`: layer row for the hero view, `image_url` row in the contract
  table, Decisions and "Deliberately stub" wording updated.
- `tasks.md`: hero-image item checked (implemented); a unit-test item for
  `heroImageURL` added and left `[ ]`.
- Code: `ILArticleStateModel.heroImageURL`, `ILArticleViewModel`,
  `ILArticleHeroImageView` (now layers `ILRemoteImageView`),
  `ILArticleViewController`. Build for `generic/platform=iOS` passes; tests not
  run, no check on device.
- Known risk: images are publisher hotlinks and may break or be blocked later;
  the placeholder covers it. BE corrected an earlier "6/60 return 403" claim:
  all 60 load (403 only came from curl with a spoofed `Mozilla/5.0` UA). The 22
  new URLs were filled in the DB on 2026-10-06 22:15, so clear any cached
  response from before then.

## v1.2 — Detail screen reads the articles API (2026-09-30)

Implementation entry. Apart from stale wording fixed in `design.md` (layer table,
"Deliberately stub") and the Status lines, requirements/design are unchanged.

- Added the shared Data layer: `ILArticleSummaryDTO` / `ILArticleDetailDTO`,
  `ILArticleMapper` (date-only `published_date` → optional `Date`, GMT; only
  http(s) `source_url` kept), `TopArticlesEndpoint` / `ArticlesPageEndpoint` /
  `ArticleDetailEndpoint`, `ILArticleRepository` + `ILArticleRepositoryImpl`
  (network-only, failures as `ILCatalogError`; `ARTICLE_NOT_FOUND` → `.notFound`).
- `ILArticleEntity` / `ILArticleItemEntity` widened for the contract
  (`publishedDate?`, `sourceName`, `sourceURL?`, `imageURL?`) — Domain changes
  the contract needed, not just Data plumbing.
- `ILArticleUseCase`: `loadArticle(id:)`, `loadNextArticles(excluding:)`;
  `ILArticleViewModel` shows the skeleton while loading, the localized error on
  failure, "Nguồn: …" (tappable when a link exists), date only when present.
  Tapping a "Đọc tiếp" row loads that article; a stale response is dropped.
- Localization: `article.dateFormat`, `article.sourceFormat`. The old
  `article.article.*` / `home.article.N.*` mock strings are no longer read and
  were left in `vi.json`.
- Verified against the running dev server (30 articles): field names of all
  three endpoints match the DTOs; `INVALID_PAGE` / `ARTICLE_NOT_FOUND` seen.
- Tests: new `ILArticleRepositoryTests`, `ILArticleUseCaseTests`; rewrote
  `ILArticleViewModelTests`. Type-checked, but NOT executed — the shared test
  target does not compile right now because `InnerLampTests/GRPC/*` imports
  `GRPCProtobuf` / `GRPCInProcessTransport`, which the target does not link
  (unrelated to articles). No visual check on device yet.

## v1.1 — Articles API contract confirmed (2026-09-30)

- `requirements.md`: 4 new EARS criteria (server load without stale content,
  error state, source attribution, optional image/date fallback). The ⚠️ on the
  missing articles contract is resolved and moved to "Open questions
  (resolved)"; a new ⚠️ tracks the client-side "Đọc tiếp" derivation (a
  decision, not backend-confirmed; does not block Phase 3).
- `design.md`: added "API contract" (3 public endpoints, envelope, Summary/
  Detail fields, error codes), a 2-step "Step-by-step Flow" (detail, then top
  list for "Đọc tiếp"), and "Decisions" (network-only, reuse `ILCatalogError`,
  optional date/image, in-memory save).
- `tasks.md`: Phase 3 unblocked; contract task ticked, the rest rewritten
  against the design and left `[ ]`.
- Reason: [BE-Developer] confirmed and verified the endpoints; the same contract
  serves `Articles` (list) and `Home` (top).

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Article
  feature (full reading screen with static catalog + in-memory save; Share not
  built).
- `requirements.md`: user story and 5 EARS acceptance criteria (load article,
  toggle save + label, switch read-next in place, share event, back). "Pending"
  records the missing articles API (with a ⚠️ on the contract), placeholder hero
  images, in-memory save, the unimplemented Share destination, and unverified
  visual QA. One resolved open question (author initials are editorial data).
- `design.md`: Layers & components table (Entity, UseCase, StateModel,
  ViewModel, leaf Coordinator, ViewController, 3 feature views, shared tokens),
  navigation flow, data flow, and a "Deliberately mock / stub" section. No
  Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 5
  tests; Phase 3 (articles API) pending on contract; Phase 4 (Share screen)
  pending; Phase 5's OKF concept left `[ ]`.
- Reason: Article was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
