# Sutras

## Overview

"Kinh sách" list screen (design handoff prototype screen `sutras`). Opened from Library's "Kinh sách"
quick-access tile and the "Kinh sách" view-all link. Sticky header (nav bar + typed search input +
two chip rows: purpose/sect and length) over a scrolling list of sutra cards; tapping a card opens
`SutraDetail`. Owned by `ILLibraryCoordinator`; `ILSutrasCoordinator` manages its own stack.
Spec: `Docs/Specs/Sutra/` (merged from the former `Docs/Specs/Sutras/`, `SutraDetail/` and `Reader/`).

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILSutrasEntity.swift` | Done | Sutra, page, purpose / tradition / kind enums, category + length filters (server enums). |
| Presentation — StateModel | `ILSutrasStateModel.swift` | Done | Chips, formatted duration/translator line, count, empty copy. |
| Data — DTO + Mapper + Repository | `ILSutraDTO`, `ILSutraMapper`, `SutrasPageEndpoint`, `ILSutraRepositoryImpl` | Done | `GET /v1/sutras` (20/page, server filters). |
| Domain — UseCase | `ILSutrasUseCase.swift` | Done | `loadFirstPage` / `loadNextPage` (keyword travels in `ILSutraFilter.query`). |
| Presentation — ViewModel | `ILSutrasViewModel.swift` | Done | 7 Inputs; paging + stale-response guard; search keyword debounced 300 ms → server `q` (≤100 chars). |
| Presentation — ViewController | `ILSutrasViewController.swift` | Done | Visual QA pending (not run on device). |
| Presentation — Coordinator | `ILSutrasCoordinator.swift` | Done | `.back`, `.openSutra` → `ILSutraDetailCoordinator`. |
| Tests | `ILSutrasViewModelTests`, `ILSutrasUseCaseTests`, `ILSutraRepositoryTests` | Written, not run | App builds for `generic/platform=iOS`; XCTest needs a device. |
| Wiring | `DIContainer` + `ILLibraryCoordinator` | Done | `makeSutras*`, `showSutras()`. |

## Navigation events

- `back` — pop + `finish()`.
- `openSutra(id:)` — push `SutraDetail` with the server slug.

## Known gaps

- "Có audio" badge follows `audio_url` (no sutra has audio yet); "downloaded" badge never shown; both badges are to be removed (`Docs/Specs/Sutra/`, BR-STR-12).
- First load (and any filter/search reload that empties the list) shows `ILSutrasSkeletonView` — card-shaped pulsing placeholders matching `ILSutrasCardView`; later pages use the footer spinner.
- "Gửi yêu cầu bản kinh" link on the empty state not built (Empty-search screen not built).

## Changelog

- 2026-10-03 — initial implementation (ui-builder)
- 2026-10-07 — integrated `GET /v1/sutras` (paging, server filters)
- 2026-10-07 — search field "×" clear button (`ILSearchInputView.showsClearButton`)
- 2026-10-07 — server-side search (`q`) + `audio_url` badge; client-side search removed (old TD-Sutras-003 resolved)
- 2026-10-16 — spec moved to `Docs/Specs/Sutra/` (the old `Docs/Specs/Sutras/`, `SutraDetail/`, `Reader/` and their assumption and tech-debt entries were deleted); no code change.
