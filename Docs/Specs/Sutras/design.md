# Sutras — Design (v1.2)

MVVM-C. `ILLibraryCoordinator.showSutras()` → `ILSutrasCoordinator` → `ILSutrasViewController`.

## Layers

| Layer | File |
|---|---|
| Domain / Entity | `ILSutrasEntity.swift` — `ILSutraEntity`, `ILSutraPageEntity`, `ILSutrasEntity` (loaded pages + `totalCount` / `lastLoadedPage` / `hasMore`), `ILSutraCategory`, `ILSutraLengthFilter`, `ILSutraFilter`, enums for purpose / tradition / kind |
| Domain / Repository | `ILSutraRepository.swift` — `loadSutras(page:filter:)`, `loadSutra(id:)` |
| Domain / UseCase | `ILSutrasUseCase.swift` — `loadFirstPage(filter:)`, `loadNextPage(after:filter:)` (de-duplicates by id), no client-side search (the keyword is part of `ILSutraFilter.query`, sent as `q`) |
| Data | `ILSutraDTO`, `ILSutraMapper`, `SutrasPageEndpoint`, `SutraDetailEndpoint`, `ILSutraRepositoryImpl` (reuses `ILCatalogPageDTO`, `ILCatalogError`) |
| Presentation | `ILSutrasViewModel` (filter incl. keyword + paging state; keyword debounced 300 ms, normalized to ≤100 chars; generation counter drops stale responses), `ILSutrasStateModel`, `ILSutrasViewController`, `Views/ILSutrasListView` (append-only diff + `ILLoadMoreFooterView` + near-bottom callback), `Views/ILSutrasCardView` |

## Step-by-step Flow

1. Trigger: screen opens (`viewDidLoad`), a chip changes, or the debounced search keyword changes. API: `GET /v1/sutras?page=1[&daily=true|purpose=…|tradition=…][&max_minutes=…][&q=…]`
   (public, no `Authorization`). Success: `data = {items, page, page_size: 20, total, total_pages}` → replace rows.
   Failure: keep rows, clear footer, emit `.failure` (`400 INVALID_PAGE` / `400 INVALID_FILTER` are caller bugs; no network → `.offline`).
2. Trigger: scroll within 120pt of the bottom, `hasMore`, no request in flight. API: same with `page = lastLoadedPage + 1`.
   Success: append unseen ids. A page past the end is `200` with `items: []` → `hasMore = false`.

Filters combine with AND on the server; the category chips are mutually exclusive (AS-Sutras-002).
`q` (≤100 chars, blank → `400 INVALID_FILTER`) is matched by the server against titles / collection / reference, diacritic-insensitive, AND-ed with the chips; `total` counts the filtered result. Each item carries `audio_url` (`""` = no audio) and a non-null `duration_minutes` (kept optional defensively). Contract source: backend `docs/specs/api/openapi.yaml`.
