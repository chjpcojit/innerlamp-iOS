# Tasks — Article

Version: 1.3
Last updated: 2026-10-06
Status: in-progress (Phase 1–3 implemented incl. hero image (v1.3), device QA pending; Phase 4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: Phase 3 replaced the original static catalog with the real articles
> API (v1.2).

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILArticleViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header + hairline, hero image,
      title/author/date, body paragraphs, quote, save/share buttons, read-next
      list — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILArticleHeroImageView`,
      `ILArticleQuoteView`, `ILArticleNextArticleListView`
- [x] Add `ILTypography.articleBody` / `articleQuote` + `ILColors.inkStrong`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `article`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILArticleEntity` + `ILArticleItemEntity`
- [x] Create `ILArticleStateModel` + `ILArticleNextArticleModel`
- [x] Create `ILArticleUseCase` / `ILArticleUseCaseImpl` (catalog, currentArticle,
      nextArticles, selectArticle, toggleSave — pure logic)
- [x] Create `ILArticleViewModel` (`Input -> Output`, `ILArticleNavEvent`,
      `articleID` parameter)
- [x] Create `ILArticleCoordinator` (leaf — `.back` pop+finish; `.share` TODO)
- [x] Wire `DIContainer.makeArticleUseCase/ViewModel/Coordinator`
- [x] Wire `ILHomeCoordinator.showArticle(_:)` via `ILHomeNavEvent.openArticle(id:)`
- [x] Unit tests: `InnerLampTests/ILArticleViewModelTests.swift` (5 tests) —
      load article, toggle save, switch read-next, nav back, nav share

## Phase 3 — API integration (contract confirmed 2026-09-30, see `design.md`)

- [x] Define the articles API contract(s) with the backend team (confirmed by
      [BE-Developer], `design.md` → "API contract")
- [x] Create `ILArticleDTO` + `ILArticleMapper` (shared summary/detail DTOs)
- [x] Create `ArticleDetailEndpoint` + `TopArticlesEndpoint` +
      `ArticlesPageEndpoint` under `Data/DataSources/Remote/`
- [x] Create `ILArticleRepository` protocol + `ILArticleRepositoryImpl` wrapping
      `NetworkService` (shared by Home / Articles / Article)
- [x] Map `ARTICLE_NOT_FOUND` in `ILCatalogErrorMapping`
- [x] Replace the static catalog in `ILArticleUseCaseImpl` with `loadArticle(id:)`
      + "Đọc tiếp" derived from top articles; show source attribution and
      loading/error state in `ILArticleViewModel`/`ViewController`
- [x] Load the hero from `image_url`: `ILArticleStateModel.heroImageURL`,
      mapped in `ILArticleViewModel`, rendered by `ILArticleHeroImageView` via
      `ILRemoteImageView` (placeholder kept on nil/failed load)
- [ ] Unit test: `ILArticleViewModelTests` asserts `heroImageURL` is mapped
      (nil and non-nil) — not written yet
- [ ] Persist `savedArticleIDs` (UserDefaultsService / Core Data) once a saved-
      articles screen exists
- [x] Update `ILArticleViewModelTests` + add a mock repository (`ILArticleUseCaseTests`,
      `ILArticleRepositoryTests`; written and type-checked — see changelog v1.2 for
      the run status)
- [ ] Visual QA on simulator/device (scroll layout, hero, dark mode)
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Share destination (pending, separate scope)

- [ ] Build the Share screen (`share`, 3 card styles) and wire `.share` to it
- [ ] Update `InnerLamp/Presentation/Scenes/Article/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Article/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/article.md` (OKF concept) — hold off until the
      articles API (Phase 3) lands. See `Docs/Specs/OKF.md`.
