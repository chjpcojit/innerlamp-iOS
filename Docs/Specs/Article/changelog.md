# Changelog — Article Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v2.0 (2026-10-15) — merge Article + Articles, align with product spec v1.0

Docs only; no code changed. Major bump: scope change (Save out, Share and shared links in), the
`Articles` spec merged in, new phases, and a new API step ("Đọc tiếp" (read next) from the related
endpoint).

- `requirements.md`: rewritten against the cross-platform product spec innerlamp-be
  `docs/product/article/product.md` @ v1.0 and ADR-0004. Header now carries `Product spec`,
  `Contract` (`openapi.yaml` @ a8a016b, info.version 1.0.0, tag Articles; planned `articlesRelated`
  from backend article v3.0 AC 20–25), `Architecture` and `Implements` (BR-ART-01…09,
  FR-ART-001…008, NFR-ART-01/02; FR-ART-009 backend only). Covers the Home block, the card, all
  articles (merged from `Docs/Specs/Articles/` v1.1), the article page, "Đọc tiếp" from the backend,
  Share with the website link and opening shared links by Universal Links: 27 EARS criteria, each
  tagged with a product ID or `(platform)`; error → UI mapping table. Removed: Save (BR-ART-09), the
  client-side "Đọc tiếp" decision, the error toast (now an empty block, FR-ART-008). Open
  `⚠️ Not confirmed` markers: empty-block retry / text (product A3, on Home, list and page), article
  not-found copy (product hand-back), website domain (product A2 / ADR-0004), Apple Team ID
  (ADR-0004), build-to-environment mapping for `applinks:` (iOS), link landing during the auth flow
  (iOS), related endpoint delivery (backend).
- `design.md`: the local "API contract" table of v1.1–v1.3 is dropped — operations are cited from
  `openapi.yaml`, never copied. New layers table naming the real files with a State column (built /
  change / planned): related endpoint + repository method, `ILArticleDetailDTO.thumbnailUrl`,
  `summary` / `language` mapping, `Core/Links/ILWebLink.swift` (link builder + Universal Link
  parser), `APIConfig.webBaseURL`, Associated Domains entitlement, `SceneDelegate` / `AppCoordinator`
  routing. Step-by-step Flows for the article page (detail → related, share, source), all articles
  (first / next page) and opening a shared link. Product vectors: backend-only, no iOS test.
- `tasks.md`: Phase 1 records what is built and still matches product v1.0 (`[x]`, verified in the
  code on 2026-10-15); Phase 2 related endpoint (blocked on backend), Phase 3 article page alignment,
  Phase 4 all articles alignment, Phase 5 Home block and card, Phase 6 Share (blocked on the domain),
  Phase 7 Universal Links (blocked on the domain), Phase 8 verification and docs. Work that exists
  but no longer matches (Save, client-side "Đọc tiếp", error toasts, end line before the first page,
  hero image without thumbnail fallback, empty author on cards) is listed as `[ ]` change tasks.
- Reason: product spec v1.0 (2026-10-15) settles the feature for every platform and its §1.5 maps
  iOS to one folder `Docs/Specs/Article/`, merging the former `Article` and `Articles` specs; the
  repo language policy requires English. `Docs/Specs/Articles/` is kept for now — its deletion and
  the OKF `home.md` update are a separate change (`tasks.md` Phase 8).

## v1.3 — Hero image loaded from `image_url` (2026-10-06)

Implementation entry following a BE change: the articles API contract (routes, schema, paging,
errors, auth) is unchanged; only data changed — `image_url` was `null` for 22 articles and now all
60 articles have an https URL.

- `requirements.md`: 2 EARS criteria (load cover into the hero with placeholder until loaded; keep
  placeholder when the image fails). Pending item rewritten: images are publisher hotlinks.
- `design.md`: layer row for the hero view, `image_url` row in the contract table, Decisions and
  "Deliberately stub" wording updated.
- `tasks.md`: hero-image item checked (implemented); a unit-test item for `heroImageURL` added and
  left `[ ]`.
- Code: `ILArticleStateModel.heroImageURL`, `ILArticleViewModel`, `ILArticleHeroImageView` (now
  layers `ILRemoteImageView`), `ILArticleViewController`. Build for `generic/platform=iOS` passes;
  tests not run, no check on device.

## v1.2 — Detail screen reads the articles API (2026-09-30)

Implementation entry: shared Data layer (`ILArticleSummaryDTO` / `ILArticleDetailDTO`,
`ILArticleMapper`, three endpoints, `ILArticleRepository` + Impl, `ARTICLE_NOT_FOUND` →
`.notFound`); `ILArticleUseCase.loadArticle(id:)` / `loadNextArticles(excluding:)`; skeleton, error,
"Nguồn: …" (Source: …) and optional date in the ViewModel. Tests written and type-checked, not run
(the shared test target did not compile because of `InnerLampTests/GRPC/*`).

## v1.1 — Articles API contract confirmed (2026-09-30)

Contract confirmed by the backend team; 4 new EARS criteria; a 2-step Step-by-step Flow (detail,
then top list for "Đọc tiếp"); Phase 3 unblocked.

## v1.0 (initial)

Spec written retroactively from the implemented Article screen (static catalog, in-memory save,
Share not built).

## Merged history — former `Docs/Specs/Articles/` (all articles)

- v1.1 (2026-09-30): the list reads the API (`loadFirstPage()` / `loadNextPage(after:)`, append on
  scroll, rows kept on failure).
- v1.0 (2026-09-30): initial retroactive spec of the "All articles" screen with the confirmed paging
  contract (page size 10, `total_pages`).
