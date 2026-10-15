# Changelog — Home Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.12 (2026-10-15) — events block moved to `Docs/Specs/Calendar/`

- `requirements.md`: the "Sự kiện Phật giáo" events criterion is replaced by a pointer to
  `Docs/Specs/Calendar/` (FR-CAL-006, BR-CAL-15, FR-CAL-007, FR-CAL-008).
- `design.md`: the "API contract — calendar events" section (and its Festivals note citing
  `AS-Festivals-002`) is replaced by a short "Events block" pointer to `Docs/Specs/Calendar/`;
  the mock-content note now points there too.
- `tasks.md`: the two open events-carousel items (offline cache `TD-Home-003`, manual device test
  `AS-Home-003`) are replaced by a pointer to `Docs/Specs/Calendar/tasks.md` Phase 4–6.
- Reason: the Calendar platform spec (v1.0) supersedes these sections; `AS-Home-003` and
  `TD-Home-003` were deleted with the other superseded festival docs (Calendar `tasks.md` Phase 9).

## v1.11 (2026-10-11) — "Sự kiện Phật giáo" carousel reads the calendar-events API

- `requirements.md`: new EARS criterion — load the whole current year from
  `GET /v1/calendar/events`, group by solar month, open on the current month,
  empty carousel on failure.
- `design.md`: new "API contract — calendar events" section (request, response,
  mapping, what Home uses vs. reserves). `tasks.md`: new checked item + two open
  ones. Headers re-synced to 1.11.
- Code: `CalendarEventsEndpoint`, `ILCalendarEventsDTO`, `ILCalendarEventMapper`,
  `ILCalendarEventsEntity`, `ILCalendarEventRepository(+Impl)`; `ILHomeUseCaseImpl`
  swaps `ILBuddhistEventUseCase` for `ILCalendarEventRepository`. Festivals is
  untouched (still local catalogue). Build for `generic/platform=iOS` passes;
  tests written but not run (no simulator/device runner).
- New: `AS-Home-003`, `TD-Home-003`.

## v1.10 (2026-10-07) — "Ảnh chùa đẹp" block reads the gallery API

- `requirements.md`: new EARS criterion — the block loads `GET /v1/gallery/top`,
  shows 3 tiles + "+N ảnh", and degrades to placeholders on failure.
- `design.md`: photos are no longer mock; `ILHomeUseCaseImpl` gets an
  `ILPhotosRepository`. `tasks.md`: photos removed from the remaining mock list,
  new checked item. Headers re-synced to 1.10.
- Code: `TopPhotosEndpoint`, `ILPhotosRepository.loadTopPhotos()`,
  `ILHomeUseCase.loadTopPhotos()`, `ILHomePhotoEntity.thumbnailURL`,
  `ILHomeViewModel.loadTopPhotos()`, `ILHomePhotoGridView` (real images). The
  "+N" overlay now hides when there are 3 or fewer photos. Build for
  `generic/platform=iOS` passes; tests not run (no profile for the UI-test runner).
- Resolves `Docs/Tech-Debt/Photos/TD-Photos-002`.

## v1.9 (2026-10-03) — Bead card opens Mala

- `requirements.md`: the "tap bead = +1" and "Bắt đầu lại" criteria are removed; the whole
  bead card (not only the "Toàn màn hình" link) now opens Mala. Matches the new design
  (`goMalaKeep`: card with "›", no reset button). `design.md` gets a note; headers re-synced.
- Code: `ILMalaCounterView` is now one tap target (`onTap`) with a "›" chevron and no reset
  button; `ILHomeViewModel.Input.beadTapped` / `resetBeadsTapped` and their tests were removed;
  `home.mala.helper` copy changed, `home.mala.reset` removed. `incrementBead` / `resetBeads`
  remain in `ILHomeUseCase` unwired (TD-Home-001).
- Assumption: AS-Home-001.

## v1.8 (2026-10-03) — "Sổ giỗ" link built

Implementation entry. `requirements.md` / `design.md` prose is unchanged.

- `ILHomeWeekCalendarView` shows a "Sổ giỗ" link beside "Lịch âm" (`home.week.memorialLink`);
  `ILHomeViewModel.Input.memorialTapped` → `ILHomeNavEvent.openMemorial` →
  `ILHomeCoordinator.showMemorial()` (child `ILMemorialCoordinator`).
- Tests: `ILHomeViewModelTests` (`memorialTapped` fires `.openMemorial`, link text localized) —
  build-verified only.

## v1.7 (2026-10-03) — "Sổ giỗ" entry point

- `requirements.md`: the navigation-target criterion gains "Sổ giỗ" (link beside "Lịch âm" in
  the week-strip header) → Memorial; Memorial added to the child-screens out-of-scope list.
- `design.md`: navigation flow gains `.openMemorial → showMemorial()`; no data-flow change
  (Memorial owns its own data).
- `tasks.md`: new unchecked item for the link + nav event + coordinator method.
- Reason: the user asked for a "Sổ giỗ" button on Home; the feature itself is specified in
  `Docs/Specs/Memorial/`. Headers of the three files re-synced to 1.7.

## v1.6 — Skeleton cards while temples / deities / articles load (2026-10-03)

Implementation entry. `requirements.md` prose is unchanged.

- Until a section's server call answers (and while it has no data), it shows 3 skeleton
  cards sized like the real ones (`ILHomeSkeletonCards`, built from the new shared
  `ILSkeletonBarView` pulse block) instead of staying blank. When the call answers: data →
  real cards, empty/failed → "Đang cập nhật" (v1.5). The carousel is not scrollable while
  the skeleton shows.
- `ILHomeStateModel` gained `templesLoading` / `deitiesLoading` / `articlesLoading`
  (`= !loaded && no data`); the three views gained `isLoading`.
- Reduce Motion → static opacity, same as `ILSkeletonLoadingView`.
- Tests: `ILHomeViewModelTests` (skeleton flags before load, cleared after answer, never with
  data) — not executed (test target does not build on `generic/platform=iOS` here).

## v1.5 — "Đang cập nhật" placeholder for temples and articles (2026-10-03)

Implementation entry. `requirements.md` prose is unchanged; `design.md` ("Top articles")
and `tasks.md` updated to match.

- Temples and articles now behave like the deities carousel: server data only; a failure
  or an empty list clears the section and shows "Đang cập nhật"
  (`home.temple.updating` / `home.article.updating`); nothing is shown while the first load
  is in flight. `ILHomeViewModel` tracks per-section load state (`LoadedSections`) instead
  of the deity-only `hasLoadedTopDeities`.
- `ILHomeStateModel` gained `templesEmptyText` / `articlesEmptyText`;
  `ILHomeTempleCarouselView` and `ILHomeArticleListView` gained `emptyText`.
- Tests: `ILHomeViewModelTests` (temples failure/empty, articles failure, no flash before
  load, no placeholder when data present). Build verified; the test target does not build
  on `generic/platform=iOS` here (Clang dependency scanning failure), so tests were not run.

## v1.4 — Articles section reads the server (2026-09-30)

Implementation entry. `requirements.md` / `design.md` prose is unchanged.

- `ILHomeUseCaseImpl` takes `ILArticleRepository`; `loadTopArticles()` maps
  `GET /v1/articles/top` to `ILHomeArticleEntity` (id = server slug). The 5 mock
  articles were removed from `getInitialState()`; the section starts empty and
  `ILHomeViewModel` fills it on `viewDidLoad`. A failure is silent (section stays
  empty), like the temple carousel.
- Tests: `ILHomeUseCaseTests` (map order, error propagation, empty initial
  state), `ILHomeViewModelTests` (articles from use case, failure keeps Home
  successful) — type-checked, not executed (see Article changelog v1.2).

## v1.3 — Top articles from the server (2026-09-30)

- `requirements.md`: new EARS criterion for the "Bài viết Phật pháp hay" section
  loading from `GET /v1/articles/top`.
- `design.md`: added the "Top articles" flow (empty until loaded, silent on
  failure, same as the other server carousels).
- `tasks.md`: new Phase 3 item for the articles section (`[ ]`); the "remaining
  mock content" item no longer lists articles.
- Reason: [BE-Developer] confirmed the articles API on 2026-09-30; canonical
  contract in `Docs/Specs/Article/design.md`. `requirements.md`/`design.md`
  headers move 1.0 → 1.3 to re-sync with `tasks.md` (v1.1–1.2 were
  implementation entries that only touched tasks/changelog).

## v1.2 — Buddha/Bodhisattva carousel: server data only (2026-09-30)

Implementation entry. `requirements.md` / `design.md` prose is unchanged.

- Removed the bundled-catalog (`phat_botat.json`) fallback and the memorial-day join from
  `ILHomeUseCaseImpl.loadTopDeities()`, which now maps `GET /v1/deities/top` only and throws
  `ILCatalogError` on failure. `ILHomeUseCaseImpl` no longer depends on `ILDeityUseCase`.
- When the server answers with no deities (or fails with nothing cached), the carousel shows
  "Đang cập nhật" instead of cards; nothing is shown while the first load is in flight.
- The server summary has no memorial days, so every card shows "Ngày vía: đang cập nhật".
- The "Xem tất cả" list screen (`Deities`) now also reads the server — see
  `InnerLamp/Presentation/Scenes/Deities/README.md`.

## v1.1 — Temple + Buddha/Bodhisattva carousels read the server (2026-09-29)

Implementation entry. `requirements.md` / `design.md` prose is unchanged; Phase 3 task
checkboxes updated.

- "Chùa Việt Nam" carousel ← `GET /v1/temples/top`; "Thư viện Phật & Bồ Tát" carousel ←
  `GET /v1/deities/top` (contract + repositories from `Docs/Specs/Temple/changelog.md` v2.1).
  `ILHomeUseCaseImpl` now takes `ILTempleRepository` + `ILDeityCatalogRepository`; both
  carousels start empty and are filled asynchronously on `viewDidLoad`.
- `ILHomeTempleEntity` now holds raw data (address, region, heritage rank, founding year);
  `ILHomeViewModel` formats the card: place = last address component without "Tỉnh " /
  "Thành phố ", region badge, note = "<rank> · Dựng năm <year>" (missing parts dropped).
- Decisions / assumptions:
  - The server deity summary has no memorial days — they are joined by id from the bundled
    catalog (`ILDeityUseCase`); a deity missing from the bundle shows no memorial line.
  - Deities fall back to the bundled catalog when the server and the cache both fail; temples
    have no equivalent fallback (mock ids differ from server ids), so that carousel stays empty.
  - No loading/error UI yet — failures are silent, like the events carousel.
  - Tapping a server temple opens the Temple detail screen, which still reads its mock catalog
    and falls back to "Từ Quang" for unknown ids — wiring the detail screen is Temple Phase 3.
- Carousels no longer rebuild (and jump back to the first card) when an unrelated state update
  re-assigns identical content.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Home feature
  (full UI + local logic, mock content, no dashboard API).
- `requirements.md`: user story and 7 EARS acceptance criteria (greeting + date,
  section rendering from mock data, bead increment/reset, the eight navigation
  targets, and the no-op sutra/offering rows). "Pending" records the missing
  dashboard API (with a ⚠️ on the contract), the temporary `KeychainService`
  name read, and the memory-only bead count. One resolved open question (lunar
  date is computed via `ILLunarCalendar`, not hardcoded).
- `design.md`: Layers & components table (Entity + 15 sub-entities/enums,
  UseCase, StateModel, ViewModel, Coordinator, ViewController, 8 feature views),
  navigation flow (owned by `ILMainTabCoordinator`, not `AppCoordinator`), the
  screen-load data flow, and a "Deliberately stubbed / mock for now" section.
  No Step-by-step Flow — no network calls.
- `tasks.md`: Phases 1–2 checked (`[x]`) reflecting the shipped UI/logic and 13
  tests; Phase 3 (dashboard API) pending, blocked on contract; Phase 4's OKF
  concept left `[ ]`.
- Reason: Home was one of the implemented features with no spec folder; written
  to close documentation debt, matching the `Docs/Specs/SignUp/` example.
