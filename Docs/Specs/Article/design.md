# Design — Article

Version: 2.0
Last updated: 2026-10-15
Status: in-progress — Home block, all articles, article page, shared Data layer (`ILArticleRepository`, three endpoints) built network-only; planned: Save removed, page states (not-found, empty block), summary notice, page image order, missing values, language, "Đọc tiếp" (read next) from the related endpoint (contract not yet in `openapi.yaml`), Share with the website link, Universal Links routing (domain open, ADR-0004)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Three entry surfaces share one Data layer
(`ILArticleRepository`, network-only — no Core Data, no cache):

- **Home block** "Bài viết Phật pháp hay" (good Dharma articles) — part of `Presentation/Scenes/Home/`
  (`ILHomeArticleListView`), fed by `ILHomeUseCase.loadTopArticles()`.
- **All articles** — `Presentation/Scenes/Articles/` (`ILArticlesCoordinator`, child of
  `ILHomeCoordinator`). Code folder name stays `Articles` (product §1.5).
- **Article page** — `Presentation/Scenes/Article/` (`ILArticleCoordinator`, leaf), pushed by Home and
  all articles with a server article `id`; planned: also by the Universal Link router.

How iOS meets the product constraints (see `requirements.md` "Constraints"):

- **Server orders, pages and picks related articles** (BR-ART-01…04). The app keeps items in the order
  received. `ILArticleUseCaseImpl.loadNextArticles(excluding:)` (first 2 of `top`, client-side) is
  replaced by the related endpoint; no client-side selection survives.
- **No offline copy** (product §2.4): failures show the empty block; nothing is stored.
- **No Save** (BR-ART-09): `toggleSave`, `savedArticleIDs`, the Save button and its strings are
  deleted, not hidden.
- **Shared links** (ADR-0004): one pure link builder / parser in `Core/Links/` is the only place that
  knows the URL shape, so Share and the Universal Link router cannot disagree, and later shareable
  features add a route there.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity (summary) | `Domain/Entities/ILArticleEntity.swift` → `ILArticleSummaryEntity` | Card row of `top` / list / related: id, category, title, author, authorInitials, readMinutes, `publishedDate?`, `imageURL?`, `thumbnailURL?`. | built; unchanged |
| Domain / Entity (detail) | `Domain/Entities/ILArticleEntity.swift` → `ILArticleItemEntity` | Article page content. Empty string = missing value (BR-ART-07). | built; **add** `thumbnailURL?`, `summary`, `language` |
| Domain / Entity (page) | `Domain/Entities/ILArticleEntity.swift` → `ILArticlePageEntity` | `items`, `page`, `totalCount`, `hasMore`. | built; unchanged |
| Domain / Entity (screen) | `Domain/Entities/ILArticleEntity.swift` → `ILArticleEntity` | `currentArticleID`, `article?`, `nextArticles` (now: related). | built; **remove** `savedArticleIDs` |
| Domain / Entity (list) | `Domain/Entities/ILArticlesEntity.swift` | `ILArticlesItemEntity` rows, `loadedCount`, `totalCount`, `lastLoadedPage`, `hasMore`. | built; unchanged |
| Domain / Entity (Home) | `Domain/Entities/ILHomeEntity.swift` → `ILHomeArticleEntity` | Home card row; `thumbnailURL` already = thumbnail ?? cover. | built; unchanged |
| Domain / Repository protocol | `Domain/Repositories/ILArticleRepository.swift` | `loadTopArticles()`, `loadArticles(page:)`, `loadArticle(id:)`; failures are `ILCatalogError` (`.notFound`, `.offline`, `.invalidPage`, `.loadFailed`). | built; **add** `loadRelatedArticles(id:) -> [ILArticleSummaryEntity]` (planned, contract pending) |
| Domain / UseCase (page) | `Domain/UseCases/Article/ILArticleUseCase.swift` | `getInitialState(articleID:)`, `loadArticle(id:)`, `loadRelatedArticles(id:)` (best effort: failure → `[]`), `shareContent(for:)` → title + link from `ILWebLink`. | built; **replace** `loadNextArticles(excluding:)` by `loadRelatedArticles(id:)`; **remove** `toggleSave`; **add** `shareContent` |
| Domain / UseCase (list) | `Domain/UseCases/Articles/ILArticlesUseCase.swift` | `loadFirstPage()`, `loadNextPage(after:)` — de-duplicates by `id`, card image = thumbnail ?? cover. | built; unchanged |
| Domain / UseCase (Home) | `Domain/UseCases/Home/ILHomeUseCase.swift` → `loadTopArticles()`, `makeArticle(from:)` | Featured cards. | built; unchanged |
| Data / DTO | `Data/DTOs/ILArticleDTO.swift` | `ILArticleSummaryDTO`, `ILArticleDetailDTO` (flat). `.convertFromSnakeCase`, no `CodingKeys`. | built; **add** optional `thumbnailUrl` to `ILArticleDetailDTO` (the detail is Summary + content in `openapi.yaml`, so the field is already sent) |
| Data / DTO (lists) | `ILCatalogTopListDTO<ILArticleSummaryDTO>`, `ILCatalogPageDTO<ILArticleSummaryDTO>` (shared) | `{items}` / `{items, page, page_size, total, total_pages}`. | built; `{items}` is reused for related |
| Data / Mapper | `Data/DTOs/Mappers/ILArticleMapper.swift` | DTO → Entity; date-only `published_date` (GMT, Gregorian, POSIX); only `http(s)` `source_url` kept; trims. | built; **map** `thumbnailUrl`, `summary`, `language` (trimmed; empty → `nil`, and no language is set on the text) |
| Data / Endpoints | `Data/DataSources/Remote/TopArticlesEndpoint.swift`, `ArticlesPageEndpoint.swift`, `ArticleDetailEndpoint.swift` | `GET /v1/articles/top`, `GET /v1/articles?page=N`, `GET /v1/articles/{id}`; `requiresAuth == false`. | built |
| Data / Endpoint (related) | `Data/DataSources/Remote/RelatedArticlesEndpoint.swift` (new) | `GET /v1/articles/{id}/related`, public. | planned — blocked on contract |
| Data / Repository | `Data/Repositories/ILArticleRepositoryImpl.swift`, `ILCatalogErrorMapping.swift` | Wraps `NetworkService`; maps errors (`ARTICLE_NOT_FOUND` → `.notFound`). | built; **add** `loadRelatedArticles(id:)` |
| Core / Config | `Core/Networking/APIConfig.swift` | Per-environment `serverBaseURL`. | built; **add** `webBaseURL` per environment (⚠️ domain) |
| Core / Links | `Core/Links/ILWebLink.swift` (new) | Pure Foundation. `articleURL(id:)` → `https://<web-domain>/articles/<id>` (id percent-encoded as a path segment); `route(for: URL) -> ILWebLinkRoute?` accepts the environment's host only, `/articles/<id>` and `/en/articles/<id>` → `.article(id:)`, anything else → `nil`. | planned |
| App / Universal Links | `App/SceneDelegate.swift`, `App/AppCoordinator.swift`, `Presentation/Scenes/Main/ILMainTabCoordinator.swift`, `Presentation/Scenes/Home/ILHomeCoordinator.swift` | `scene(_:continue:)` and `connectionOptions.userActivities` (cold start) take `NSUserActivityTypeBrowsingWeb`; `ILWebLink.route` → `AppCoordinator.open(route:)` → main tab selects Home → `ILHomeCoordinator.showArticle(id)`; `nil` route → `UIApplication.shared.open(url)` (Safari). | planned (⚠️ landing during the auth flow) |
| App / Entitlements | `InnerLamp/InnerLamp.entitlements` | Today: App Attest only. Add `com.apple.developer.associated-domains` = `applinks:<web-domain>` per environment; Associated Domains capability on the App ID `weedigital.vn.InnerLamp`. | planned (⚠️ domain, environment mapping) |
| Presentation / Article page | `Presentation/Scenes/Article/ILArticleViewModel.swift`, `ILArticleStateModel.swift`, `ILArticleViewController.swift`, `Views/ILArticleHeroImageView.swift`, `Views/ILArticleQuoteView.swift`, `Views/ILArticleNextArticleListView.swift` | VM: load detail, then related (best effort, stale responses dropped); `content` / `notFound` / `empty block` states; StateModel fields for notice, no-body text, language, visibility of author / quote / source / "Đọc tiếp"; hero URL = cover ?? thumbnail; share event. VC: sticky header band (category + read time), hero, title, author, body, quote, source + notice, "Chia sẻ" alone, "Đọc tiếp"; text views get the article language (`accessibilityLanguage` + `.languageIdentifier` attribute on the attributed strings); not-found and empty-block views. | built; **change** (Phase 3) |
| Presentation / Article coordinator | `Presentation/Scenes/Article/ILArticleCoordinator.swift` | Leaf. `.back` → pop + `finish()`; `.openURL` → Safari; `.share(title:url:)` → `UIActivityViewController` (today a TODO). | built; **change** `.share` |
| Presentation / All articles | `Presentation/Scenes/Articles/ILArticlesViewModel.swift`, `ILArticlesStateModel.swift`, `ILArticlesViewController.swift`, `ILArticlesCoordinator.swift`, `Views/ILArticlesListView.swift` | Header "{loaded} / {total} bài", load-more at 120 pt from the end, in-flight guard, append-only cards, footer `ILLoadMoreFooterView` (loading / end). | built; **change**: first-page failure / `total` 0 → empty block (today a toast + the footer's end line); footer `.end` only after a loaded last page; later-page failure without toast |
| Presentation / Home block | `Presentation/Scenes/Home/ILHomeViewModel.swift`, `ILHomeStateModel.swift`, `Views/ILHomeArticleListView.swift`, `Views/ILHomeSkeletonCards.swift` | Featured cards, "Xem tất cả" (See all), skeleton while loading, empty text when none / failed. | built; **change** empty block copy / action (⚠️ A3) |
| Presentation / Card | `Presentation/Common/DesignSystem/Components/ILArticleCardView.swift` | Shared card (Home + all articles): `ILRemoteImageView` thumbnail, category eyebrow, 2-line title, "author · read time". | built; **change** meta line without empty author, category label hidden when empty |
| Localization | `Resources/Localization/vi.json` | `article.*`, `articles.*`, `home.article.*`. | **add** `article.summaryNotice`, `article.noBody`, `article.notFound.*` (⚠️ copy), empty-block keys (⚠️ A3); **remove** `article.save`, `article.saved`, the mock `article.article.*` and `home.article.N.*` keys |
| DI | `App/DIContainer.swift` | `makeArticleRepository`, `makeArticle{UseCase,ViewModel,Coordinator}`, `makeArticles{UseCase,ViewModel,Coordinator}`. | built; unchanged (the use case gets no new dependency; `ILWebLink` is static) |
| Tests | `InnerLampTests/ILArticleViewModelTests.swift`, `ILArticleUseCaseTests.swift`, `ILArticleRepositoryTests.swift`, `ILArticlesViewModelTests.swift`, `ILHomeViewModelTests.swift`, `ILHomeUseCaseTests.swift` | Stub repositories / use cases. Written and type-checked 2026-09-30, never run. | built (old behavior); **rewrite** per phase; **add** `ILWebLinkTests.swift` |

## Navigation flow

```
SceneDelegate (Universal Link, planned)
  └─ ILWebLink.route(url)
       ├─ .article(id) → AppCoordinator.open(route:) → ILMainTabCoordinator (select Home)
       │                   → ILHomeCoordinator.showArticle(id)            (⚠️ during auth flow)
       └─ nil          → UIApplication.shared.open(url)                    (Safari)

ILHomeCoordinator (Home tab)
  ├─ (.openArticle(id)) → showArticle(id)  → ILArticleCoordinator (leaf)
  └─ (.openArticles)    → showArticles()   → ILArticlesCoordinator
                            push ILArticlesViewController
                            (.openArticle(id)) → ILArticleCoordinator (leaf)
                            (.back) → pop + finish()

ILArticleCoordinator
  push ILArticleViewController
  (.back)              → pop + finish()
  (.openURL(url))      → Safari (source link)
  (.share(title, url)) → UIActivityViewController            (today: TODO, no-op)
  "Đọc tiếp" tap       → same screen, new id (ViewModel), scroll to top
```

## Step-by-step Flow — Article page

```
Step 1 — Load the article (this feature)
- Trigger: article page `viewDidLoad`, a tap on a "Đọc tiếp" card, or a routed Universal Link
- Pre-condition: id from a card / related item / link path; the previous article's content is cleared
  and the skeleton is shown
- API: GET /v1/articles/{id} (articlesGet, public) — exists at a8a016b
    - Success → map to ILArticleItemEntity → ILArticleStateModel (FR-ART-004 order, BR-ART-05…08);
      "Chia sẻ" enabled; go to Step 2
    - Failure (404 ARTICLE_NOT_FOUND → ILCatalogError.notFound) → not-found state with back; no Step 2
    - Failure (offline / unreachable / 500 / other) → empty block with back; no Step 2 (⚠️ retry, A3)
    - A response whose id is no longer current is dropped (user tapped another "Đọc tiếp" card)

Step 2 — Load "Đọc tiếp" (this feature)
- Trigger: Step 1 succeeded
- Pre-condition: the id is still current
- API: GET /v1/articles/{id}/related (articlesRelated, public, {items: [ArticleSummary]}, 0–2 items)
  ⚠️ Not confirmed: planned contract — backend article requirements / design v3.0 (AC 20–25), not
  built, not yet in openapi.yaml (backend tasks.md Phase 7). Until it ships, today's code keeps
  GET /v1/articles/top and takes the first 2 other ids (drift, BR-ART-04).
    - Success (1–2 items) → "Đọc tiếp" cards in the order received
    - Success (0 items) → section hidden
    - Failure (any, incl. 404) → section hidden; Step 1's content unchanged
    - A response whose id is no longer current is dropped

Step 3 — Share (this feature, no network)
- Trigger: tap "Chia sẻ" on a loaded article
- Pre-condition: Step 1 succeeded
- Effect: ILArticleUseCase.shareContent → (title, ILWebLink.articleURL(id)) → .share(title:url:) →
  UIActivityViewController([title, url]). ⚠️ Not confirmed: web domain per environment (ADR-0004).

Step 4 — Open the source (this feature, no network)
- Trigger: tap "Nguồn: …" when sourceURL is http(s)
- Effect: .openURL → Safari. No in-app browser.
```

## Step-by-step Flow — All articles

```
Step 1 — First page (this feature)
- Trigger: `viewDidLoad`
- API: GET /v1/articles?page=1 (articlesList) — page size fixed by the server (10), never sent
    - Success, total > 0 → cards in order, header "{loaded} / {total} bài",
      hasMore = page < total_pages && items non-empty; hasMore false → end line
    - Success, total == 0 → empty block
    - Failure (any) → empty block; no end line, no count (⚠️ retry, A3)

Step 2 — Next page (this feature)
- Trigger: scroll within 120 pt of the end, hasMore == true, no request in flight
- API: GET /v1/articles?page=<last + 1>
    - Success → append cards whose id is not shown yet; update count and hasMore; last / empty page →
      end line "Bạn đã xem hết bài viết"
    - Failure → keep cards, remove the loading line; the next reach of the end repeats this step
```

The Home block makes a single call (`GET /v1/articles/top`, no cache, empty block on failure or no
item) and needs no step list.

## Step-by-step Flow — Open a shared link (ADR-0004)

```
Step 1 — Receive the link (App)
- Trigger: iOS opens the app for https://<web-domain>/articles/<id> (warm: scene(_:continue:);
  cold: connectionOptions.userActivities in scene(_:willConnectTo:options:))
- Pre-condition: associated domain verified by iOS for this build (entitlement + website
  apple-app-site-association listing the app and /articles/*, /en/articles/*)
    - Route .article(id) → Step 2
    - Route nil (other host or path) → UIApplication.shared.open(url); stop

Step 2 — Show the page (App → this feature)
- Trigger: Step 1 routed .article(id)
- Pre-condition: main tab shown
  ⚠️ Not confirmed: behavior while splash / onboarding / sign-up / login is on screen (hold the
  route until the main tab appears, or present over the auth flow).
- Effect: select the Home tab, ILHomeCoordinator.showArticle(id) → Article page Step 1 (above);
  unknown id → not-found state (never another article, ADR-0004 convention 3)
```

## Product vectors

- `rules/article-order.json` (BR-ART-01) and `rules/article-related.json` (BR-ART-04) are run by the
  backend only (product §4.1; both rules "Applies to: Backend"). iOS neither sorts nor picks related
  articles, so no iOS vector test and no `Scripts/sync-product-vectors.sh` entry for this feature.

## Deliberately stubbed for now

- **"Đọc tiếp" source.** Until the related endpoint is in `openapi.yaml`, `loadNextArticles(excluding:)`
  stays (first 2 featured, client-side). It is a known drift, not a fallback to keep: Phase 2 deletes it
  in the same change that adds the endpoint.
- **Share.** `ILArticleCoordinator` handles `.share` with a `// TODO`; it stays a no-op until the web
  domain is known (Phase 6). Building the link with a guessed domain is not allowed.

## Design reference

Prototype `InnerLamp Prototype.dc.html` (product §1.5): home §11 "Bài viết Phật pháp hay", screens
"Tất cả bài viết" and "Bài viết Phật pháp". Per-screen implementation notes:
`InnerLamp/Presentation/Scenes/Article/README.md`, `InnerLamp/Presentation/Scenes/Articles/README.md`.
