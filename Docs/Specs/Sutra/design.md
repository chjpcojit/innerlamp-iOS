# Design — Sutra

Version: 1.0
Last updated: 2026-10-16
Status: in-progress — list (`GET /v1/sutras`, paging, chips, server search) and sutra page (`GET /v1/sutras/{id}`, all fields) built network-only on `ILSutraRepository`; the reading view, its use case and entity are a sample catalogue with a simulated player and are replaced by `GET /v1/sutras/{id}/lines`; planned: product-rule default version, per-version facts and licence labels, linked deities that open the deity page, version switch, shared font size, error / empty / not-found states with retry, 60-minute chip and product labels, day-based quote on Home

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Three scenes share one Data layer (`ILSutraRepository`,
network-only — no Core Data, no cache beyond `ILRemoteImageView`) and one Domain vocabulary
(`ILSutrasEntity.swift`, `ILSutraDetailEntity.swift`):

- **List** — `Presentation/Scenes/Sutras/` (`ILSutrasCoordinator`, child of `ILLibraryCoordinator`).
- **Sutra page** — `Presentation/Scenes/SutraDetail/` (`ILSutraDetailCoordinator`, opened by the list,
  the Library tile and the Deity page).
- **Reading view** — `Presentation/Scenes/Reader/` (`ILReaderCoordinator`, child of
  `ILSutraDetailCoordinator`). It is given the sutra the page already loaded, so it makes no detail call
  of its own (it is reached only from the sutra page).
- **Quote of the day** — `Domain/UseCases/SutraQuote/` (bundled catalogue in Core Data), used by the Home
  hero card and the lunar-day page.

Code folder names stay `Sutras` / `SutraDetail` / `Reader` (product §1.5). No rename is planned.

How iOS meets the product constraints (see `requirements.md` "Constraints"):

- **Server order, filter, search, paging** (BR-STR-02…04). The app appends pages in the order received,
  de-duplicates by `id`, sends the chips as `daily` / `purpose` / `tradition` and `max_minutes` and the
  term as `q`; a generation counter drops superseded responses. No client-side sorting or matching.
- **Vietnamese-first, rule on the device** (BR-STR-05). A pure Domain rule (`ILSutraVersionRules`) picks the
  opening version; the product vector file is run against it. Titles come from `titles.vi`.
- **Text as stored** (BR-STR-06). The reading view renders `text` and the section name of each line; the
  mock catalogue's gloss, cue and opening ritual have no counterpart in the new entity.
- **Licence, source and notice per version** (BR-STR-07). `ILSutraLicense` maps the contract's licence
  codes; an unknown code produces no line; the notice follows `review_status`.
- **No audio, no player** (BR-STR-12). `ILReaderUseCase` has no playback state; the page and the reading
  view lose the player, progress, download and timer-driven highlight.
- **One font-size choice** (BR-STR-11). The reading view reads and writes the choice stored by the
  Language feature (`il_scripture_font_size`, `ILScriptureFontSize`: Nhỏ / Vừa / Lớn / Rất lớn), through
  the existing preferences use case, so the Language screen and the reading view always agree.
- **Quote rule on the device** (BR-STR-10). A pure rule gives the quote number of a Gregorian date; the
  product vector file is run against it. Home no longer asks for a random quote.
- **Shared load-failure presentation.** Where nothing is shown yet (list page 1, sutra page, reading view
  page 1) an `ILStateView` error block with a "Thử lại" (Try again) control replaces the content — the
  same pattern as `Docs/Specs/Gallery/design.md`; the offline variant when `ILCatalogError.offline`; the
  not-found variant for `.notFound`. Where content is shown (later pages) a footer "Thử lại" is used.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity (list) | `Domain/Entities/ILSutrasEntity.swift` → `ILSutraPurpose`, `ILSutraTradition`, `ILSutraKind`, `ILSutraEntity`, `ILSutraPageEntity`, `ILSutraCategory`, `ILSutraLengthFilter`, `ILSutraFilter`, `ILSutrasEntity` | Wire-shaped enums with `wireValue`; a text (id, title, original title, kind, tradition, collection, reference, daily chant, purposes, duration); a page; the loaded pages (`totalCount`, `lastLoadedPage`, `hasMore`); chips and filter. | built; **add** `summary` to `ILSutraEntity`, `ILSutraLengthFilter.upTo60`; **remove** `translator`, `audioURL` / `hasAudio` |
| Domain / Entity (page) | `Domain/Entities/ILSutraDetailEntity.swift` → `ILSutraDetailSutraEntity`, `ILSutraDetailDeityEntity`, `ILSutraDeityRole`, `ILSutraTranslationVariant`, `ILSutraDetailAlternateTitleEntity`, `ILSutraDetailEntity` | One text with all fields of `GET /v1/sutras/{id}`; deities with role; other-language titles; `isUnreviewed`. Today the version fields (`translator`, `sourceName`, `sourceURL`, `license`, `lineCount`, `variant`, `licenseURL`, `licenseNote`, `note`, `chapters`) describe **one** preferred translation. | built; **change** to `versions: [ILSutraVersionEntity]`; deity entity gains `thumbnailURL`; **remove** `ILSutraDetailChapterEntity` (sections move into the version) |
| Domain / Entity (version) | `Domain/Entities/ILSutraDetailEntity.swift` → `ILSutraVersionEntity`, `ILSutraSectionEntity`, `ILSutraLicense` (new) | A version: `key`, `language`, `variant`, translator, source name / URL, `license` (`.cc0`, `.ccByNC`, `.publicDomain`, `.copyAllowed`, `.unknown`), licence URL / note, note, `lineCount`, `sections` (`name`, `startLine`, `lineCount`). Unknown licence code → `.unknown`. | planned |
| Domain / Rule (version) | `Domain/UseCases/SutraDetail/ILSutraVersionRules.swift` (new) | Pure: `openingVersion(in:) -> ILSutraVersionEntity?` — among `language == "vi"`, rank translation < chant < meaning < poem (unknown variant last), ties by order received; no Vietnamese version → first in order received (⚠️ Appendix A item 5). Unit of `rules/sutra-default-version.json`. | planned |
| Domain / Entity (reading) | `Domain/Entities/ILReaderEntity.swift` → `ILSutraLineEntity` (`number`, `text`, `section: String?`), `ILSutraLinesPageEntity` (`lines`, `page`, `pageSize`, `totalCount`, `totalPages`), `ILReaderEntity` (sutra, current version key, loaded lines, `startLine`, `lastLoadedPage`, `hasMore`) | The window of lines of one version. No playback, cue, gloss or narrator. | **rewrite** (today: sample catalogue, `ILReaderCue`, `ILReaderLineEntity`, `ILReaderSectionEntity`, `ILReaderSutraEntity`, playback state) |
| Domain / Repository protocol | `Domain/Repositories/ILSutraRepository.swift` | `loadSutras(page:filter:)`, `loadSutra(id:)`, **new** `loadLines(sutraID:versionKey:page:) -> ILSutraLinesPageEntity` (`page_size` fixed at 200 by the implementation). Every failure is an `ILCatalogError` (`.notFound` for `SUTRA_NOT_FOUND` and `TRANSLATION_NOT_FOUND`). | built; **add** `loadLines` |
| Domain / UseCase (list) | `Domain/UseCases/Sutras/ILSutrasUseCase.swift` | `loadFirstPage(filter:)`, `loadNextPage(after:filter:)` (de-duplicates by id; no-op when `hasMore == false`). | built; unchanged |
| Domain / UseCase (page) | `Domain/UseCases/SutraDetail/ILSutraDetailUseCase.swift` | `loadSutra(id:)`. | built; unchanged |
| Domain / UseCase (reading) | `Domain/UseCases/Reader/ILReaderUseCase.swift` | `open(sutra:versionKey:startLine:)` (opening version via `ILSutraVersionRules` when no key), `loadNext(after:)` (appends, no-op when `hasMore == false`), `switchVersion(_:)`, `jump(toSection:)` (page of `start_n`, lines before it dropped). Pure window logic over the repository; no timer, no catalogue. | **rewrite** (today `getInitialState`, `togglePlayPause`, `seek`, `setSpeed`, `advance`, `progress`, `elapsedSeconds` over an 11-sutra sample catalogue) |
| Domain / UseCase (font size) | `Domain/UseCases/Language/ILLanguageUseCase.swift` (Language feature) | Already stores `ILScriptureFontSize` under `il_scripture_font_size`. **Add** a narrow `scriptureFontSize()` / `setScriptureFontSize(_:)` so the reading view does not re-apply language and theme. | **change** (Language feature; coordinate with `Docs/Specs/Language/`) |
| Domain / Rule (quote) | `Domain/UseCases/SutraQuote/ILSutraQuoteUseCase.swift` | `quote(for date:)` and pure `quoteNumber(for:totalCount:calendar:) -> Int?` = (day of year of the **Gregorian** date % count) + 1; the stored row is `number − 1` in id order (valid while the file numbers its quotes 1…N, product BR-STR-10). `prepare()` seeds the bundled catalogue. Unit of `rules/sutra-daily-quote.json`. | built (`quoteIndex`, uses `Calendar.current`); **change** to a fixed Gregorian calendar in the device time zone, number 1…N; **remove** `randomQuote()` (orphaned by Home) and the unused `randomQuotes(count:)` |
| Domain / Entity (quote) | `Domain/Entities/ILSutraQuoteEntity.swift`, `Domain/Entities/ILHomeEntity.swift` → `ILHomeQuoteEntity(quote:)` | Quote facts (sutra name, translator, chapter number and name, verse number, content); display form (4 poetic lines via `ILSutraVerseLineSplitter`, attribution line). | built; **change** the attribution line to carry translator and chapter (⚠️ copy) |
| Domain / UseCase (Home) | `Domain/UseCases/Home/ILHomeUseCase.swift` → `loadRandomVerse()` | Returns the fallback verse on any failure. | **change** to `loadDailyVerse(on:)` using `quote(for:)` |
| Data / DTO | `Data/DTOs/ILSutraDTO.swift` → `ILSutraDTO`, `ILSutraDeityDTO`, `ILSutraTranslationDTO`, `ILSutraSectionDTO` | List and detail share one DTO (`.convertFromSnakeCase`, no `CodingKeys`); detail-only fields optional. | built; **add** `ILSutraDeityDTO.thumbnailUrl` (optional) |
| Data / DTO (lines) | `Data/DTOs/ILSutraDTO.swift` → `ILSutraLinesDTO` `{translation, items: [{n, text, section?}], page, page_size, total, total_pages}` (new) | Wire shape of `sutrasLines`; not the shared `ILCatalogPageDTO` because it names `translation`. | planned |
| Data / Mapper | `Data/DTOs/Mappers/ILSutraMapper.swift` | DTO → Entity; `vi` → `en` → `pli` → any → slug title; original title; unknown enum values dropped; only absolute `http(s)` links kept. | built; **change**: map **all** translations to `ILSutraVersionEntity` (licence code → `ILSutraLicense`, `.unknown` for unknown), map list `summary` and deity thumbnail, map lines; **remove** the "first Vietnamese translation" picker (`AS-Sutras-003`) |
| Data / Endpoints | `Data/DataSources/Remote/SutrasPageEndpoint.swift`, `SutraDetailEndpoint.swift`; `SutraLinesEndpoint.swift` (new) | `GET /v1/sutras?page=N[&daily=true\|purpose=\|tradition=][&max_minutes=][&q=]`, `GET /v1/sutras/{id}`, `GET /v1/sutras/{id}/lines?translation=&page=&page_size=200`; all `requiresAuth == false`. | built; **add** lines endpoint; `max_minutes=60` needs no endpoint change |
| Data / Repository | `Data/Repositories/ILSutraRepositoryImpl.swift` | Wraps `NetworkService`; `ILCatalogError.from`; `hasMore` = non-empty raw page and `page < total_pages` for both pages and lines. | built; **add** `loadLines` |
| Data / Quote | `Data/DataSources/Local/ILSutraQuoteLocalDataSource.swift`, `ILSutraQuoteMO.swift`, `Data/DTOs/ILSutraQuoteDTO.swift`, `Data/Repositories/ILSutraQuoteRepositoryImpl.swift` | Seeds the bundled `sutra_quotes_300.json` into Core Data on launch (`SceneDelegate.seedSutraQuotes`), fetches by offset. | built; unchanged. The JSON is git-ignored (`*.json`), so a fresh checkout has no catalogue (⚠️ Appendix A item 3). |
| Presentation / List | `Presentation/Scenes/Sutras/ILSutrasViewModel.swift`, `ILSutrasStateModel.swift`, `ILSutrasViewController.swift`, `Views/ILSutrasListView.swift`, `Views/ILSutrasCardView.swift`, `Views/ILSutrasSkeletonView.swift` | VM: page 1 on load / chip / debounced term, load-more with in-flight guard, generation counter, `normalizedQuery`; StateModel: chips, count, items, footer, state kind; VC: sticky band + `ILNavBar` + search + two chip rows. | built; **change**: duration chip 60; product labels; card = title, original, kind · tradition, collection · code, "khoảng N phút", summary, daily mark; **remove** audio / downloaded badges and the translator line; error state with "Thử lại" on page 1 failure; three empty cases; footer "Thử lại" for a later page; drop the `matchedFormat` count variant |
| Presentation / List coordinator | `Presentation/Scenes/Sutras/ILSutrasCoordinator.swift` | `.back` → pop + `finish()`; `.openSutra(id)` → `ILSutraDetailCoordinator`. | built; unchanged |
| Presentation / Sutra page | `Presentation/Scenes/SutraDetail/ILSutraDetailViewModel.swift`, `ILSutraDetailStateModel.swift`, `ILSutraDetailViewController.swift`, `Views/ILSutraDetailHeroView.swift`, `ILSutraDetailInfoView.swift`, `ILSutraDetailChapterListView.swift` | VM: `loadSutra` → state (hero, "Giới thiệu", "Thông tin", versions, notice, deities, contents); events back / reader / deity / link. VC: pinned `ILNavBar`, hero, info blocks, contents, bottom "Đọc kinh" bar. | built; **change**: per-version blocks with licence labels (new `Views/ILSutraDetailVersionView.swift`), short unreviewed notice, deity rows with thumbnail that open the deity page (new `Views/ILSutraDetailDeityRowView.swift`), contents rows carry their `start_n`, state view for error / not found with retry; **remove** the "Tải về máy" action, `playButton`, `ILSutraDetailPlayButton`, progress card, `hasAudio`, the `.download` and `.openPlayer` events and the hero audio chip |
| Presentation / Sutra page coordinator | `Presentation/Scenes/SutraDetail/ILSutraDetailCoordinator.swift` | `.back` → pop + `finish()`; `.openReader(sutra, startLine)` → `ILReaderCoordinator`; `.openDeity(id)` → `ILDeityCoordinator` (new); `.openLink(url)` → `UIApplication.shared.open`. | built; **change** (see Navigation flow) |
| Presentation / Reading view | `Presentation/Scenes/Reader/ILReaderViewModel.swift`, `ILReaderStateModel.swift`, `ILReaderViewController.swift`, `Views/ILReaderLineCell.swift` (+ heading cell) | VM: open, load-next near the end, jump, switch version, font size; StateModel: rows (heading / line), contents, version choices, font index, footer / error state; VC: `ILNavBar` header with "Aa", contents and version controls; `UITableView` of rows, incremental append (`AGENTS.md` §4.6), fonts `ILTypography.readerLineFonts` (17 / 20 / 23 / 26), colours from the adaptive tokens. | **rewrite** (today: timer tick publisher, speed, seek, auto-scroll, three themes, in-memory preferences, keep-awake) |
| Presentation / Reading views | `Presentation/Scenes/Reader/Views/ILReaderFontSizePanelView.swift` (new, from the size half of `ILReaderSettingsPanelView`), `ILReaderContentsView.swift` (new), `ILReaderVersionPickerView.swift` (new) | Four size tiles; list of sections (name, line count) with tap-to-jump; version list. | planned |
| Presentation / Reading coordinator | `Presentation/Scenes/Reader/ILReaderCoordinator.swift` | Leaf; `.back` → pop + `finish()`. | built; **change** to take the sutra entity and the start line instead of a bare id |
| Presentation / Removed views | `Presentation/Scenes/Reader/Views/ILReaderAutoScrollRowView.swift`, `ILReaderControlsView.swift`, `ILReaderPalette.swift`, `ILReaderSettingsPanelView.swift`; `ILColors.Reader.*` and the six `ILReader*` colour assets; `ILTypography.readerGloss`, `readerCue`, `readerOptionSize` and `ILMetrics.radiusOptionTile` / `radiusLineHighlight` once unused (verify with `grep`); `ILSutraDetailPlayButton` | Timer controls, pace chips, auto-scroll, three backgrounds, cue glyphs. `ILPlayPauseButton` stays (Talk and MeditationHub use it). | planned (delete) |
| Presentation / Home + lunar day | `Presentation/Scenes/Home/ILHomeViewModel.swift` (`loadRandomVerse`), `ILHomeCoordinator.swift`; `Presentation/Scenes/LunarDayDetail/ILLunarDayDetailViewModel.swift`; `App/DIContainer.swift` (`makeLunarDayDetail*`) | Home loads the quote of today's device date on load and when the date changes; `ILHomeNavEvent.openLunarDayDetail(date:verse:)` loses `verse`; the lunar-day page always loads `quote(for: date)`. | **change** |
| Localization | `Resources/Localization/vi.json` | `sutras.*`, `sutraDetail.*`, `reader.*`, `home.lunar.verse.*`, `sutraQuote.*`. | **change** chip / card / notice / licence / attribution strings; **add** state, version, contents, licence-label strings; **remove** the `sutras.mock.*`, `sutraDetail.mock.*`, `reader.phapcu.*`, `reader.tamkinh.*`, `reader.open.*`, `reader.placeholder.*`, `reader.theme.*`, `reader.speed.*`, `reader.seek.*`, `reader.status.*`, `reader.legend.*`, `reader.autoScroll.*`, `reader.keepAwake.*`, `reader.hint.*`, `reader.playback.*`, `sutras.badge.*`, `sutraDetail.download` / `chant` / `play` keys |
| DI | `App/DIContainer.swift` | `makeSutraRepository`, `makeSutras*`, `makeSutraDetail*`, `makeReader*`, `makeSutraQuoteUseCase`. | built; **change** `makeReaderUseCase` (repository, no sample catalogue), `makeReaderViewModel` / `makeReaderCoordinator` (sutra entity + start line, language use case), `makeSutraDetailCoordinator` (deity navigation) |
| Tests | `InnerLampTests/ILSutrasViewModelTests.swift`, `ILSutrasUseCaseTests.swift`, `ILSutraRepositoryTests.swift`, `ILSutraDetailViewModelTests.swift`, `ILSutraDetailUseCaseTests.swift`, `ILReaderViewModelTests.swift`, `ILReaderUseCaseTests.swift`, `ILSutraQuoteUseCaseTests.swift`, `ILSutraQuoteRepositoryTests.swift`, `ILSutraVerseLineSplitterTests.swift`, `ILSutraTestSupport.swift`, `ILHomeUseCaseTests.swift`, `ILHomeViewModelTests.swift` | Stub repositories / use cases. Written and type-checked, never run by a docs change. | built (old behaviour); **rewrite** per phase; **add** `ILSutraVersionRulesTests`, `ILSutraMapperTests`, `ILSutraProductVectorTests` |

## Navigation flow

```
ILLibraryCoordinator (Library tab)
  ├─ .sutras ("Kinh sách" tile / "Xem tất cả") → ILSutrasCoordinator
  │    push ILSutrasViewController
  │    (.back)           → pop + finish()
  │    (.openSutra(id))  → ILSutraDetailCoordinator(sutraID)
  └─ .openItem(.sutra, id) → ILSutraDetailCoordinator(sutraID)   (sample ids → not-found state until the Library spec)
ILDeityCoordinator
  └─ .openSutra(id)        → ILSutraDetailCoordinator(sutraID)   (Docs/Specs/Deity/)

ILSutraDetailCoordinator
  push ILSutraDetailViewController
  (.back)                          → pop + finish()
  (.openReader(sutra, startLine?)) → ILReaderCoordinator(sutra, startLine)   (nil = first line of the opening version)
  (.openDeity(id))                 → ILDeityCoordinator(deityID)            (planned)
  (.openLink(url))                 → UIApplication.shared.open → Safari
  [.download, .openPlayer removed — BR-STR-12]

ILReaderCoordinator
  push ILReaderViewController
  (.back)  → pop + finish()

ILHomeCoordinator
  └─ (.openLunarDayDetail(date)) → ILLunarDayDetailCoordinator(date)     (planned: no verse handed over)
```

## Step-by-step Flow — List

```
Step 1 — Page 1 (this feature)
- Trigger: `viewDidLoad`, a chip change, the debounced term, or "Thử lại" on the error state
- Pre-condition: none (public); term trimmed, cut to 100 characters, blank → no `q`
- API: GET /v1/sutras?page=1[&daily=true | &purpose=<CODE> | &tradition=<CODE>][&max_minutes=5|15|30|60][&q=<term>] (sutrasList)
  Filters combine with AND on the server; page size is read from the response, never sent.
    - Success, total > 0 → rows in order received, count "{N} bản kinh" with N = total,
      hasMore = items non-empty && page < total_pages
    - Success, total == 0 → empty state; which case (library empty / chips / search) follows from the
      chips and term sent
    - Failure (any) → error state with "Thử lại" in place of the list (offline variant when
      ILCatalogError.offline); "Thử lại" repeats this step

Step 2 — Next page (this feature)
- Trigger: list scrolled within 120 pt of the end
- Pre-condition: hasMore == true, no page request in flight, same chips and term as Step 1
- API: GET /v1/sutras?page=<last + 1> with the same query items
    - Success → append rows whose id is not shown yet; update hasMore; last / empty page → end note
    - Failure → keep rows, clear the loading line, footer "Thử lại" repeats this step

Step 3 — Chip or term change (this feature)
- Trigger: a chip other than the selected one, or a debounced term that differs from the last one
- Effect: invalidate the in-flight request (generation counter), clear the rows, run Step 1 with the new
  filter; a response of an older generation is dropped

Step 4 — Open a text (SutraDetail, boundary)
- Trigger: tap on a card → .openSutra(id) → ILSutraDetailCoordinator, which runs the page flow below
```

## Step-by-step Flow — Sutra page and reading view

```
Step 1 — Load the sutra page (this feature)
- Trigger: `viewDidLoad`, or "Thử lại"
- Pre-condition: id from a card, a deity's related sutra, or the Library
- API: GET /v1/sutras/{id} (sutrasGet)
    - Success → map to the page (hero, summary, information, versions with facts, notice, deities,
      contents of the opening version); the opening version = ILSutraVersionRules.openingVersion
    - Failure (404 SUTRA_NOT_FOUND) → ILCatalogError.notFound → not-found state with back, no "Thử lại"
    - Failure (offline / unreachable) → error state, offline variant, "Thử lại"
    - Failure (otherwise) → error state with "Thử lại"

Step 2 — Open the reading view (this feature, no network)
- Trigger: "Đọc kinh" → startLine nil; a contents row → startLine = that section's start_n
- Pre-condition: Step 1 succeeded (the entity is handed to ILReaderCoordinator)

Step 3 — First lines (this feature)
- Trigger: reading view `viewDidLoad`, "Thử lại", a version switch, or a contents jump
- Pre-condition: version key = opening version (or the chosen one); page p = 1, or
  floor((start_n − 1) / page_size) + 1 for a jump / startLine; page_size is the one fixed value 200 on
  every call of a text (the contract warns that pages shift if it changes)
- API: GET /v1/sutras/{id}/lines?translation=<key>&page=<p>&page_size=200 (sutrasLines)
    - Success → rows: a heading row where `section` changes between consecutive lines, then the lines
      (n ≥ start_n only for a jump); hasMore = items non-empty && page < total_pages
    - Failure (404 SUTRA_NOT_FOUND / TRANSLATION_NOT_FOUND) → not-found state with back
    - Failure (otherwise) → error state with "Thử lại"

Step 4 — Further pages (this feature)
- Trigger: the visible rows come within about 40 lines of the last loaded line
- Pre-condition: hasMore == true, no lines request in flight for this text and version
- API: GET /v1/sutras/{id}/lines?translation=<key>&page=<last + 1>&page_size=200
    - Success → append lines whose n is not shown yet; update hasMore
    - Failure → keep rows, footer "Thử lại" repeats this step

Step 5 — Jump or switch (this feature)
- Trigger: a section chosen in the contents / another version chosen
- Effect: cancel the in-flight request, clear the rows, run Step 3 with the new start / version; the
  contents control lists the sections of the version now shown; a response of an older request is dropped

Step 6 — Font size (this feature, no network)
- Trigger: a tile in the "Aa" panel
- Effect: ILLanguageUseCase.setScriptureFontSize → rows re-rendered at ILTypography.readerLineFonts[index];
  the Language screen reads the same stored value
```

## Step-by-step Flow — Quote of the day

```
Step 1 — Quote of a date (this feature, no network)
- Trigger: Home `viewDidLoad` and each later appearance on a new device date; the lunar-day page opening
- Pre-condition: the bundled catalogue is seeded (`SceneDelegate.seedSutraQuotes` → `prepare()`)
- Effect: number = (dayOfYear(Gregorian date, device time zone) % count) + 1 → catalogue row number − 1 in id
  order → ILHomeQuoteEntity (lines, attribution)
    - Success → the card shows the quote
    - Failure / empty catalogue → the built-in fallback verse (⚠️ Appendix A item 14)
```

## Product vectors

Only two of the four vector files apply on iOS (product §4.1): `rules/sutra-default-version.json`
(`ILSutraVersionRules`) and `rules/sutra-daily-quote.json` (the quote number). `sutra-browse.json` and
`sutra-search-match.json` are backend-only for iOS: the server orders, filters and searches.

- `Scripts/sync-product-vectors.sh` (the script Memorial, Onboarding and Calendar plan; whichever feature
  lands first creates it — it does not exist yet) copies
  `../innerlamp-be/docs/product/sutra/rules/{sutra-default-version,sutra-daily-quote}.json` into
  `InnerLampTests/ProductVectors/sutra/` and records the source commit and file hashes in
  `InnerLampTests/ProductVectors/sutra/SOURCE`. The copy is a pinned mirror, never edited by hand; a
  mismatch is fixed in innerlamp-be (via `ba-writer`) and re-synced. A bundled copy is needed because
  XCTest runs on a device, which cannot read the sibling checkout.
- `ILSutraProductVectorTests` loads every case from the test bundle:
  - `sutra-default-version.json` → `ILSutraVersionRules.openingVersion` (`lang`, `variant`, `ordinal` →
    `ILSutraVersionEntity` in `ordinal` order); asserts the returned `key` equals `default_key`.
  - `sutra-daily-quote.json` → `ILSutraQuoteUseCaseImpl.quoteNumber` with a Gregorian calendar (the date
    parsed from `YYYY-MM-DD`) and `quote_count`; asserts `day_of_year` (`ordinality(of: .day, in: .year)`)
    and `quote_number`.

## Caching

None for sutras: list, page and lines are network-only. Product §2.4 allows ("may") keeping the last
loaded pages readable offline; this release does not, so a lost connection shows the offline error state
with "Thử lại" and never a stale or sample text. The quote of the day needs no network (bundled
catalogue in Core Data). Thumbnails use the `ILRemoteImageView` memory / HTTP cache only.

## Deliberately not built

- **Audio, player, download, progress** (BR-STR-12, product §1.2). The page and the reading view have no
  control for them. The Library's, Downloads' and Player's sample content belongs to their own specs
  (`Docs/Specs/Library/`, `Docs/Specs/Downloads/`, `Docs/Specs/Player/`).
- **Auto-scroll with a highlighted line** — waits for the product answer (Appendix A item 4); no timer
  code is kept "just in case".
- **Reading-view cues and glosses** (bell, wooden fish, English gloss, "KHAI KINH"): invented by the app,
  not in the stored text (BR-STR-06).
- **Offline library** (see "Caching").
- **A client-side search or filter**: the server does both (BR-STR-03, BR-STR-04).
