# Design — Article

Version: 1.3
Last updated: 2026-10-06
Status: in-progress — full reading screen backed by the articles API, hero loads `image_url` (v1.3);
Share not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Article ("Bài viết Phật pháp") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen** — `ILArticleCoordinator` has no delegate.
It is created by `ILHomeCoordinator` (tapping an article card on Home →
`ILHomeNavEvent.openArticle(id:)`) and pushed onto the Home tab's
`BaseNavigationController`. It is parameterized by an `articleID` passed through
the coordinator and ViewModel. The UseCase reads the
server through `ILArticleRepository` (contract below); there is no static catalog
any more.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILArticleEntity.swift` | `ILArticleItemEntity` (detail: category, title, author, authorInitials, `publishedDate?`, readMinutes, bodyParagraphs, quote, quoteSource, sourceName, `sourceURL?`, `imageURL?`), `ILArticleSummaryEntity` (Home / list / "Đọc tiếp"), `ILArticlePageEntity` and `ILArticleEntity` (`currentArticleID`, loaded `article?`, `nextArticles`, `savedArticleIDs`). No UI-only state. |
| Domain / Repository | `Domain/Repositories/ILArticleRepository.swift` | `loadTopArticles()`, `loadArticles(page:)`, `loadArticle(id:)` — Entities in/out, `ILCatalogError` on failure. Implemented by `Data/Repositories/ILArticleRepositoryImpl.swift` (DTOs in `Data/DTOs/ILArticleDTO.swift`, `Mappers/ILArticleMapper.swift`, endpoints `TopArticlesEndpoint` / `ArticlesPageEndpoint` / `ArticleDetailEndpoint`). |
| Domain / UseCase | `Domain/UseCases/Article/ILArticleUseCase.swift` | `getInitialState(articleID:)`, `loadArticle(id:)`, `loadNextArticles(excluding:)` (best effort, 2 items from top), `toggleSave(_:in:)` (in-memory). |
| Presentation / State | `Presentation/Scenes/Article/ILArticleStateModel.swift` | UI-only state: header labels, title/author/initials/date-read text, body paragraphs, quote, saved flag + button title, read-more title, `nextArticles`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Article/ILArticleViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILArticleNavEvent` (`.back`, `.share`); Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/Article/ILArticleCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop + `finish()`; `.share` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Article/ILArticleViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Article/Views/ILArticleHeroImageView.swift`, `ILArticleQuoteView.swift`, `ILArticleNextArticleListView.swift` | Hero, quote, and read-next list views. The hero layers a shared `ILRemoteImageView` (loads `heroImageURL`) over the tint + category placeholder; a nil URL or a failed load leaves the placeholder visible. |
| Shared tokens | `DesignSystem/Tokens/ILTypography.swift` + `ILColors.swift` | `articleBody` (Lora 16px), `articleQuote` (Lora 18px italic), `ILColors.inkStrong`. |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showArticle(id) → ILArticleCoordinator               (leaf, no delegate)
       push ILArticleViewController
       (.back) → pop + finish()
       (.share) → TODO (Share screen not built)
```

## Data flow

1. `ILArticleViewModel` loads `useCase.getInitialState(articleID:)` and maps the
   current article to `ILArticleStateModel` (with "N phút đọc" formatting).
2. `handleSaveTapped()` → `toggleSave` mutates `savedArticleIDs` in memory.
3. `handleNextArticleTapped(id)` → `selectArticle` switches the current article
   in place.
4. `handleShareTapped` → emits `.share`.

The flow below is implemented (`ILArticleUseCaseImpl` → `ILArticleRepositoryImpl`).

## API contract ("Phật pháp hay" articles) — confirmed 2026-09-30

Source: [BE-Developer], verified against the real dev server (30 articles in
the DB). This section is the single canonical contract; `Articles` and `Home`
specs reference it.

- **Host**: `APIConfig.serverBaseURL` (dev = the Mac's LAN IP, port 8080). All
  three endpoints are **public** — no `Authorization` header.
- **Envelope**: success `{"success":true,"data":{...}}`; failure
  `{"success":false,"error":{"code","message","type"},"details":{...}}`.
  Keys are snake_case (decoded with `.convertFromSnakeCase`).
- **Common errors**: `500 INTERNAL_ERROR` (no detail leaked); unknown
  route / wrong method → 404 / 405, also in the envelope.

**Summary object** (Home cards + list rows, no body):

| Field | Type | Notes |
|---|---|---|
| `id` | string | Stable slug, e.g. `vipassana-nghe-thuat-song` |
| `title`, `category`, `author`, `author_initials`, `summary` | string | Non-null |
| `published_date` | string? | Date-only `yyyy-MM-dd`, no time/zone; `null` for most articles |
| `read_minutes` | int | |
| `tags` | [string] | Never `null` |
| `image_url` | string? | string or `null` (all 60 articles have a URL as of 2026-10-06; hotlinked from publisher sites, all https) |

| # | Call | Params | 200 `data` | Failures |
|---|---|---|---|---|
| 1 | `GET /v1/articles/top` | none (no `limit`; server returns 5 in curated `sort_order`, not by date/popularity) | `{"items":[Summary ×5]}` | — |
| 2 | `GET /v1/articles?page=N` | `page` 1-based, default 1; fixed `page_size` = 10; no size/filter/search/category | `{"items":[Summary],"page","page_size","total","total_pages"}` — a page past the end is `200` with empty `items` | `400 INVALID_PAGE` (`details.field = "page"`) for a non-positive-integer page |
| 3 | `GET /v1/articles/{id}` | path `id` = slug | Summary + `body_paragraphs` ([string], **plain text**, one element per paragraph — no HTML/markdown), `quote`, `quote_source`, `language` (`"vi"`), `source_name` (e.g. "Báo Giác Ngộ"), `source_url` (original article), `license` | `404 ARTICLE_NOT_FOUND` |

There is no related-articles field and no `publishedAt` datetime. Stop load-more
when `page >= total_pages` (or when `items` is empty).

## Step-by-step Flow

The screen makes up to two sequential calls, so each step is spelled out:

1. **Load detail** — Trigger: `viewDidLoad` (or tapping a "Đọc tiếp" row).
   Pre-condition: `articleID` known. API: `GET /v1/articles/{id}`.
   Success → map to `ILArticleItemEntity`, render. Failure `ARTICLE_NOT_FOUND`
   → `ILCatalogError.notFound`; no connection / timeout → `.offline`; anything
   else → `.loadFailed`. On failure the screen shows the localized error and no
   article content.
2. **Load "Đọc tiếp" candidates** — Trigger: step 1 succeeded.
   Pre-condition: none beyond step 1. API: `GET /v1/articles/top`.
   Success → the first 2 items whose `id` differs from the current article.
   Failure → the "Đọc tiếp" section is hidden; the article itself stays
   readable (best-effort, never blocks step 1).

> Decision (not backend-confirmed): "Đọc tiếp" is derived client-side from
> `/v1/articles/top` because the API exposes no related-articles field.

## Decisions

- **Network-only, no Core Data cache** for articles in this version (the
  Temple/Deity catalogs cache; articles do not — nothing asked for offline
  reading). Failures surface as `ILCatalogError`.
- **Error type**: reuse `ILCatalogError` (Domain); the Data-layer error mapping
  adds `ARTICLE_NOT_FOUND` → `.notFound` next to the temple/deity codes.
- `published_date` is parsed to an optional `Date` (fixed Gregorian calendar,
  GMT, `en_US_POSIX`) in the Mapper and formatted for display in the ViewModel;
  `image_url` maps to an optional `String` (`imageURL`), passed unchanged to
  `ILArticleStateModel.heroImageURL` and loaded by `ILRemoteImageView` — the
  host is never rebuilt on the client.
- **Save** stays in-memory (`savedArticleIDs`); no backend endpoint exists.

## Deliberately stub

Save state is in-memory only (`savedArticleIDs`; no backend endpoint, no "Saved"
screen). The Share destination is a TODO (`tasks.md` Phase 4). The hero image is a
hotlink to the publisher's site; failures (e.g. a publisher blocking the
request) silently keep the placeholder — no retry, no disk cache beyond `URLSession.shared`'s HTTP cache.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `article` / `Component.ARTICLES`. See `InnerLamp/Presentation/Scenes/
Article/README.md` for the full design-vs-implementation comparison and
changelog.
