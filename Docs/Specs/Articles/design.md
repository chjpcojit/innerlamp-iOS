# Design — Articles

Version: 1.1
Last updated: 2026-09-30
Status: in-progress — UI, navigation and API paging implemented

> See `changelog.md` in this folder for the version history of this spec.

## Overview

"All articles" follows MVVM-C + Clean Architecture per `AGENTS.md`.
`ILArticlesCoordinator` is a leaf flow created by `ILHomeCoordinator` ("Xem tất
cả" on the Home articles section); it forwards row taps to `ILArticleCoordinator`
and pops + finishes on back. No delegate.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILArticlesEntity.swift` | `ILArticlesItemEntity` (id, category, title, author, readMinutes) and `ILArticlesEntity` (rows, `loadedCount`, `totalCount`, `hasMore`). |
| Domain / Repository | `Domain/Repositories/ILArticleRepository.swift` | Shared with Article/Home: `loadTopArticles()`, `loadArticles(page:)`, `loadArticle(id:)` — Entities in/out, `ILCatalogError` on failure. |
| Domain / UseCase | `Domain/UseCases/Articles/ILArticlesUseCase.swift` | `loadFirstPage()` and `loadNextPage(after:)` over the repository; the entity carries `lastLoadedPage` / `hasMore`, rows already loaded are never duplicated. |
| Presentation | `ILArticlesStateModel` / `ILArticlesViewModel` / `ILArticlesCoordinator` / `ILArticlesViewController` | Existing; the ViewModel now drives load / load-more / error from the UseCase. |

## Navigation flow

```
ILHomeCoordinator ("Xem tất cả")
  └─ ILArticlesCoordinator
       (.openArticle(id)) → ILArticleCoordinator (push)
       (.back) → pop + finish()
```

## Step-by-step Flow

Contract: `Docs/Specs/Article/design.md` → "API contract" (public endpoints,
snake_case envelope).

1. **First page** — Trigger: `viewDidLoad`. API: `GET /v1/articles?page=1`.
   Success → rows + `total` (subtitle "N / total"). Failure → localized error,
   empty list.
2. **Next page** — Trigger: scroll near the bottom. Pre-condition: not already
   loading and `hasMore`. API: `GET /v1/articles?page=N+1`. Success → append,
   `hasMore = page < total_pages && !items.isEmpty`. Failure → keep loaded rows,
   clear the footer spinner, show an error. `400 INVALID_PAGE` is a client bug
   (`ILCatalogError.invalidPage`).

## Decisions

- Network-only (no Core Data cache); `published_date`/`image_url` are not shown
  on list rows, so they are not carried into `ILArticlesItemEntity`.
- Page size is not sent — the server fixes it at 10.
