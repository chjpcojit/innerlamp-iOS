# Tasks — Article

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer today; Phase 3 tracks replacing the
> static catalog with a real articles API.

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

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the articles API contract(s) (see `requirements.md` Pending).
> Everything below is blocked until a contract exists.

- [ ] Define the articles API contract(s) with the backend team
- [ ] Create `ILArticleDTO` + `ILArticleMapper` (once the contract is confirmed)
- [ ] Create `ArticleEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILArticleRepository` protocol + `ILArticleRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the static catalog in `ILArticleUseCaseImpl` with real data + real
      hero images
- [ ] Persist `savedArticleIDs` (UserDefaultsService / Core Data) once a saved-
      articles screen exists
- [ ] Update `ILArticleViewModelTests` + add a mock repository
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
