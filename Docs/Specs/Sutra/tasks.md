# Tasks — Sutra

Version: 1.0
Last updated: 2026-10-16
Implements: `requirements.md` v1.0 · design: `design.md` v1.0

Retroactive and prospective. `[x]` means the code exists on main today; `[ ]` is work the product spec
(§4.2) marks planned or drift for iOS. Unit tests that were written but never run stay `[ ]` for the run.

## Phase 1 — Built and kept

- [x] Data layer for list and detail: `SutrasEndpoint`, `SutraDetailEndpoint`, DTOs, `ILSutraMapper`, `ILSutraRepository` + implementation, paging, stale-response guard
- [x] List screen shell: paging, debounced server search, topic and duration chips (combine), clear button
- [x] Sutra page shell: info sections, source links, deity list
- [x] Four reader font presets (17 / 20 / 23 / 26 pt)
- [x] Quote catalogue seeded into Core Data; `quote(for:)` day arithmetic; `LunarDayDetail` calls `quote(for:)`
- [x] DI wiring (`DIContainer`) for the three scenes and the quote use case
- [x] Unit tests written (`ILSutrasViewModelTests`, `ILSutrasUseCaseTests`, `ILSutraRepositoryTests`, `ILSutraTestSupport`) — not run
- [x] Folder READMEs for `Sutras`, `SutraDetail`, `Reader`

## Phase 2 — Data and Domain

- [ ] `SutraLinesEndpoint` (`GET /v1/sutras/{id}/lines`, `page_size=200`, constant for one read, optional `version`/`lang` as the contract defines) + DTO + mapper (`n`, `text`, `section`; sections `{name,start_n,line_count}`) (FR-STR-006, FR-STR-007)
- [ ] `ILSutraRepository.loadLines(sutraId:versionId:cursor:)` and its use case; map network / 404 / empty into `ILCatalogError`
- [ ] `ILSutraVersionEntity`, `ILSutraLicense` (CC0-1.0, CC-BY-NC-4.0, PUBLIC_DOMAIN, COPY_ALLOWED, UNKNOWN) and `ILSutraVersionRules` (Vietnamese-first default, BR-STR-05)
- [ ] Map every translation to a version entity; remove the "first Vietnamese translation" picker (AS-Sutras-003)
- [ ] Map list `summary` and deity `thumbnail_url`
- [ ] "60 minutes" duration chip filter value (BR-STR-03)
- [ ] Unit tests for the lines mapper, repository and version rules

## Phase 3 — List alignment

- [ ] Chip and card copy per the product spec; `⚠️ Not confirmed (product)` items stay as listed in `requirements.md`
- [ ] Page 1 failure shows one error state with "Thử lại" (Retry); no empty state and alert together
- [ ] Empty state for no results; no sample content anywhere
- [ ] Remove the dead "downloaded" and audio-badge pieces that the product spec drops
- [ ] Update `ILSutrasViewModelTests` for the above

## Phase 4 — Sutra page alignment

- [ ] Default version via `ILSutraVersionRules`; per-version facts (translator, source, licence)
- [ ] Licence label from `ILSutraLicense` (no raw code) and the short unreviewed notice for `review_status` UNREVIEWED
- [ ] Linked deities open the deity page (`.openDeity(id)`) with the thumbnail
- [ ] Not-found and error states with retry; no sample content
- [ ] "Read" action opens the reading view at the first line (`.openReader(sutra,startLine)`)
- [ ] Update `SutraDetail` tests

## Phase 5 — Reading view rewrite

Resolves TD-SutraDetail-003, TD-Reader-001, TD-Reader-002, TD-Reader-003.

- [ ] Replace the mock catalogue with real lines in 200-line windows, fetched as the reader scrolls
- [ ] Table of contents from `sections`; section jump
- [ ] Version switch in the reading view
- [ ] Font size from `ILScriptureFontSize` shared with the settings (`il_scripture_font_size`); 4 sizes; drop the 3 backgrounds
- [ ] Remove the timer / simulated player views, tokens and assets
- [ ] Error and empty states with retry
- [ ] Delete the unused mock files and tests; add reader view model tests

## Phase 6 — Daily quote

- [ ] Gregorian calendar in `ILSutraQuoteUseCase` (not `Calendar.current`); `quoteNumber` per BR-STR-10
- [ ] `Home.loadDailyVerse(on:)` replaces the random pick; refresh on date rollover
- [ ] `LunarDayDetail` no longer receives a handed-in verse
- [ ] Attribution line (translator, chapter) per the product spec
- [ ] Remove `randomQuote` and its callers
- [ ] Decide the fallback quote and quote-file location (`⚠️ Not confirmed (product)`)

## Phase 7 — Product vectors

- [ ] `Scripts/sync-product-vectors.sh` mirrors `sutra-default-version.json` and `sutra-daily-quote.json` into `InnerLampTests/ProductVectors/sutra/`
- [ ] `ILSutraProductVectorTests` runs the 6 default-version cases and 8 daily-quote cases

## Phase 8 — Hand-offs

- [ ] Library: pass sutra ids to the reading view (separate Library spec)
- [ ] Deity: accept `.openDeity(id)` from the sutra page
- [ ] Language: expose `scriptureFontSize()` / `setScriptureFontSize`
- [ ] Home spec: daily verse follows `loadDailyVerse(on:)`

## Phase 9 — Verification and docs

- [ ] Build and run all new and existing unit tests on a device or simulator destination
- [ ] Manual QA on device: list, sutra page, reading view, quote
- [ ] NFR-STR-01 and NFR-STR-02 checks
- [ ] Update READMEs and the OKF concept
- [ ] Separate clean-up change: remove `Docs/Specs/Sutras/`, `SutraDetail/`, `Reader/` and their assumption and tech-debt entries
- [ ] Add `Docs/Assumptions/Sutra/` for the platform assumptions
- [ ] `python3 -I Scripts/doc-check.py --changed` passes
