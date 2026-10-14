# Design — SutraDetail

Version: 1.4
Last updated: 2026-10-11
Status: in-progress — real sutra API wired; Reader/Player still mock; Download not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

SutraDetail ("Chi tiết bài kinh") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen with two child pushes** — Reader (`.openReader`)
and Player (`.openPlayer`) — and no delegate. It is created by
`ILLibraryCoordinator` (tapping a sutra row → `ILLibraryNavEvent.openItem(id:kind:)`
with `kind == .sutra`) and pushed onto the Library tab's `BaseNavigationController`.
It is parameterized by a `sutraID` (the server slug) and loads it with one network call.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSutraDetailEntity.swift` | `ILSutraDetailChapterEntity` (id, number, title, lineCount), `ILSutraDetailSutraEntity` (title, original title, kind, tradition, collection, reference, purposes, daily chant, duration?, translator, source, license, line count, chapters), `ILSutraDetailEntity` (`sutra`). |
| Domain / Repository | `Domain/Repositories/ILSutraRepository.swift` | `loadSutra(id:)` (shared with Sutras). |
| Domain / UseCase | `Domain/UseCases/SutraDetail/ILSutraDetailUseCase.swift` | `loadSutra(id:) async throws`. |
| Data | `ILSutraDTO`, `ILSutraMapper`, `SutraDetailEndpoint`, `ILSutraRepositoryImpl` | `GET /v1/sutras/{id}`; maps `sections[]` of the preferred (Vietnamese) translation to chapters. |
| Presentation / State | `.../ILSutraDetailStateModel.swift` | UI-only state: kicker/title/original name/meta, chip models, description, translator/source/license text, TOC count + chapter models. No UIKit import. |
| Presentation / ViewModel | `.../ILSutraDetailViewModel.swift` | `Input -> Output`; owns `ILSutraDetailNavEvent`; loads on `viewDidLoad` (`.loading` → `.success` / `.failure`); Entity→StateModel formatting. |
| v1.4 additions | — | Data: `ILSutraDTO` gains `summary`, `deities` (`ILSutraDeityDTO`: `deityId`, `role`, `nameVi`), `originalTitle`, `author`, `hanTranslator`, `hanTranslationYear`, `referenceNote`, `reviewStatus`; `ILSutraTranslationDTO` gains `variant`, `licenseUrl`, `licenseNote`, `note` (all optional). Mapper: `original_title` preferred for the hero name; other-language `titles` → `alternateTitles` (Pāli, Sanskrit, Chinese, English, then the rest); unknown deity role / variant → `nil`; only `http(s)` links kept. Domain: `ILSutraDetailSutraEntity` gains `summary`, `author`, `hanTranslator`, `hanTranslationYear`, `referenceNote`, `deities`, `alternateTitles`, `isUnreviewed`, `variant`, `licenseURL`, `licenseNote`, `note`. Presentation: `ILSutraDetailStateModel.infoSections` (Giới thiệu · Thông tin · Bản dịch & giấy phép · Lưu ý; empty rows and sections dropped; replaces `translatorText`); `Views/ILSutraDetailInfoView` renders them; a link row emits `.openLink(URL)` and the Coordinator opens it in the browser. |
| Presentation / Coordinator | `.../ILSutraDetailCoordinator.swift` | Leaf — unchanged. |
| Presentation / ViewController | `.../ILSutraDetailViewController.swift` | Hides the description, translator and TOC blocks when empty. |
| Feature-scoped views | `Views/ILSutraDetailHeroView.swift`, `ILSutraDetailChapterListView.swift` | Unchanged. |

## Navigation flow

```
ILLibraryCoordinator (Library tab)
  └─ showSutraDetail(sutraID) → ILSutraDetailCoordinator   (no delegate)
       push ILSutraDetailViewController
       (.back) → pop + finish()
       (.openReader) → showReader() → ILReaderCoordinator
       (.openPlayer) → showPlayer() → ILPlayerCoordinator
       (.download) → TODO (Download screen not built)
       (.openLink(url)) → UIApplication.shared.open(url)
```

## Data flow

1. `ILSutraDetailViewModel` emits `.loading`, calls `useCase.loadSutra(id:)` and maps the result to
   `ILSutraDetailStateModel` (kicker, "N dòng · duration", translator / source / license lines, chapter
   subtitles).
2. Nav taps emit `.back` / `.openReader` / `.download` / `.openPlayer`.

### Step-by-step Flow

1. Trigger: screen opens. API: `GET /v1/sutras/{id}` (public, no `Authorization`). Success:
   `data` = sutra + `review_status` + `translations[]` (with `source_name`, `source_url`, `note`,
   `sections[{name, start_n, line_count}]`). Failure: `404 SUTRA_NOT_FOUND` → `ILCatalogError.notFound`;
   no network → `.offline`; anything else → `.loadFailed`.

   Contract re-confirmed by the backend team on 2026-10-11 (unchanged vs BE HEAD `87c3083`). Fields the
   backend returns that the iOS DTO/UI does **not** consume yet (see AS-SutraDetail-002):
   `summary` (AI-drafted, unreviewed, `""` when absent), `deities[]`, detail-only `original_title`,
   `author`, `han_translator`, `han_translation_year` (int|null), `reference_note`, `review_status`
   (`"UNREVIEWED"`), and per translation `variant` (`translation|chant|meaning|poem`), `license_url`,
   `license_note`, `note`. `audio_url` is `""` for every text today; there is no thumbnail.
   v1.4: the screen consumes **all** of the fields above — still one call, no new endpoint. Empty strings
   and `null` are treated as absent and hide their row/block; `summary` stays hidden until the backend
   seeds it. Nested shapes confirmed by the backend on 2026-10-11: `deities[]` = `{deity_id, role, name_vi, thumbnail_url}`, `sections[]` = `{name, start_n, line_count}`; `review_status` is an open string.
   Backend note (v3.0, 2026-10-11): the service no longer seeds sutras on startup (`make seed-sutras`),
   so an empty database yields an empty catalog, not an error.

## Deliberately not wired

Audio file / narrator / reading progress / section durations (TD-SutraDetail-002; `audio_url` is `""` for
every text today), Reader and Player
catalogs (TD-SutraDetail-003), `.download` (TODO).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isDetail`. See `InnerLamp/Presentation/Scenes/SutraDetail/README.md` for
the full design-vs-implementation comparison and changelog.
