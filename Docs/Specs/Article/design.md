# Design — Article

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full reading screen with static catalog + in-memory save;
Share not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Article ("Bài viết Phật pháp") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen** — `ILArticleCoordinator` has no delegate.
It is created by `ILHomeCoordinator` (tapping an article card on Home →
`ILHomeNavEvent.openArticle(id:)`) and pushed onto the Home tab's
`BaseNavigationController`. It is parameterized by an `articleID` passed through
the coordinator and ViewModel. There is **no network** — the UseCase returns a
static catalog.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILArticleEntity.swift` | `ILArticleItemEntity` (category, title, author, authorInitials, date, readMinutes, bodyParagraphs, quote, quoteSource) and `ILArticleEntity` (articles catalog, `currentArticleID`, `savedArticleIDs` set). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Article/ILArticleUseCase.swift` | `getInitialState(articleID:)` (static 5-article catalog), `currentArticle(in:)`, `nextArticles(after:in:)` (2 wrap-around), `selectArticle(_:in:)`, `toggleSave(_:in:)` (in-memory). Pure logic, no network/disk. |
| Presentation / State | `Presentation/Scenes/Article/ILArticleStateModel.swift` | UI-only state: header labels, title/author/initials/date-read text, body paragraphs, quote, saved flag + button title, read-more title, `nextArticles`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Article/ILArticleViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILArticleNavEvent` (`.back`, `.share`); Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/Article/ILArticleCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop + `finish()`; `.share` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Article/ILArticleViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Article/Views/ILArticleHeroImageView.swift`, `ILArticleQuoteView.swift`, `ILArticleNextArticleListView.swift` | Hero, quote, and read-next list views. |
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

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

The catalog is a static `Component.ARTICLES` (5 articles) built in
`ILArticleUseCaseImpl.makeArticleCatalog()`. Save state is in-memory only.
The Share destination is a TODO. Completing these is `tasks.md` Phases 3–4.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `article` / `Component.ARTICLES`. See `InnerLamp/Presentation/Scenes/
Article/README.md` for the full design-vs-implementation comparison and
changelog.
