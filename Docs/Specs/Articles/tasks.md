# Tasks — Articles

Version: 1.1
Last updated: 2026-09-30
Status: in-progress (Phase 1–3 implemented, device QA pending)

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI

- [x] `ILArticlesViewController` with header, article rows, load-more footer
- [x] Feature-scoped row view under `Presentation/Scenes/Articles/Views/`

## Phase 2 — Logic

- [x] `ILArticlesEntity` / `ILArticlesItemEntity`
- [x] `ILArticlesStateModel` / `ILArticlesViewModel` / `ILArticlesCoordinator`
- [x] `DIContainer.makeArticlesUseCase/ViewModel/Coordinator`
- [x] Unit tests: `InnerLampTests/ILArticlesViewModelTests.swift`

## Phase 3 — API integration (contract confirmed 2026-09-30)

- [x] Shared Data layer from `Docs/Specs/Article/tasks.md` Phase 3 (DTO, Mapper,
      Endpoints, `ILArticleRepository` + Impl)
- [x] `ILArticlesUseCase`: replace the static catalog with `loadFirstPage()` /
      `loadNextPage()`
- [x] `ILArticlesViewModel`: async load, load-more append, error state
- [x] Update `ILArticlesViewModelTests` (mock use case) + `ILArticlesUseCaseTests`
- [ ] Manual test on a physical device against the dev backend

## Phase 4 — Documentation

- [ ] Update `InnerLamp/Presentation/Scenes/Articles/README.md`
- [ ] `Docs/Knowledge/features/articles.md` (OKF concept) after verification
