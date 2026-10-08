# Changelog — Articles Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. Newest version first.

## v1.1 — List reads the articles API (2026-09-30)

Implementation entry. Requirements/design prose unchanged except stale wording
(layer table row, removed "Deliberately stub" section) and the Status lines.

- `ILArticlesUseCase`: `loadFirstPage()` / `loadNextPage(after:)` over the shared
  `ILArticleRepository` (see `Docs/Specs/Article/changelog.md` v1.2). The entity
  now carries `lastLoadedPage` + a stored `hasMore` (from the server's
  `total_pages`, or an empty page).
- `ILArticlesViewModel`: starts empty, loads page 1 on `viewDidLoad`, appends on
  scroll; the footer spinner covers the first page too. On failure the loaded
  rows are kept, the spinner is cleared, then the error is emitted (before, the
  spinner stayed on).
- Tests: `ILArticlesViewModelTests` rewritten, `ILArticlesUseCaseTests` added —
  type-checked, not executed (see Article changelog v1.2 for why).

## v1.0 (initial) — 2026-09-30

- Spec written retroactively for the implemented "All articles" screen and
  extended with the backend contract confirmed by [BE-Developer] on 2026-09-30
  (`GET /v1/articles?page=N`, page size 10, `total_pages`).
- `requirements.md`: 6 EARS criteria (first page, next page, stop at the end,
  page failure, row tap, back).
- `design.md`: layers, navigation, and a 2-step Step-by-step Flow.
- `tasks.md`: Phases 1–2 `[x]`; Phase 3 `[ ]`.
