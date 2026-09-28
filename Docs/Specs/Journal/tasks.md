# Tasks — Journal

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILJournalViewController` (list), `ILJournalWriteViewController`,
      `ILJournalEntryViewController` extending `BaseViewController`
- [ ] `setupViews()`: list (weekly chart card + entry rows + "Ghi lại hôm nay"),
      write (date, textarea + counter, tag chips, save), entry (header, thời
      khóa card, mood/dedication/tags/content, "Đã hành trong ngày", actions)
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire taps to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screens `journal`, `write`, `entry`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILJournalEntity` (pure business fields only)
- [ ] Create `ILJournalStateModel` (UI state, no UIKit import)
- [ ] Create `ILJournalUseCase` / `ILJournalUseCaseImpl`:
      - `listEntries()` / `getEntry(id:)` / `saveEntry(...)` (local)
      - `weeklyMinutes()` aggregation
      - `sync()` — stub only (no backend contract)
- [ ] Create `ILJournalRepository` protocol + `ILJournalRepositoryImpl` (Core Data)
- [ ] Create `ILJournalViewModel` (`Input -> Output`, `ILJournalNavEvent`)
- [ ] Create `ILJournalCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeJournal{UseCase,Repository,ViewModel,Coordinator}`
- [ ] Wire Home/Profile/Stats coordinators' `showJournal()` + delegate conformance
- [ ] Unit tests: `ILJournalViewModelTests.swift` + `ILJournalUseCaseTests.swift`
      (mock repository)

## Phase 3 — Sync integration (pending; local-first works without it)

> Backend sync unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm whether/when the journal syncs and its contract
- [ ] Create DTO + Mapper (only if a backend contract is confirmed)
- [ ] Implement the sync path in `ILJournalRepositoryImpl`; replace the stub
- [ ] Map errors to feature error cases
- [ ] Manual test against a real/staging backend once available (if applicable)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Journal/README.md`
- [ ] `Docs/Knowledge/features/journal.md` (OKF concept) — after Phase 2/3

## Deferred (separate feature, not blocking Journal)

- SessionComplete, SutraDetail, Mala, Stats, LunarCalendar.
