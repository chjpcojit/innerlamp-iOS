# Tasks — Stats

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phases 1–2 done; Phase 3 pending — real data integration)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was scaffolded UI-first by `il-screen-builder` from the
> design handoff (`isStats` screen), with the data source stubbed to sample
> data — matching the project's preferred workflow (see `Docs/Specs/OKF.md`).
> Checked items below reflect what shipped; unchecked items are real pending
> work, not hypothetical examples.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILStatsViewController` extending `BaseViewController`
- [x] `setupViews()`: sticky `ILNavBar` header band + scroll view + content
      stack holding the streak card, tiles row, chart card, mix card, and
      reminder card
- [x] `setupConstraints()`: pin the header band to the top, scroll content
      per design tokens (`ILColors`/`ILTypography`/`ILMetrics`)
- [x] `bindViewModel()`: wire `viewDidLoad`/`backTapped`/`reminderTapped`
      to `Input`, render `Output.state` via `updateUI(with:)`
- [x] Add shared Design System components: `ILStatHeroCardView`,
      `ILStatTileView`, `ILStatBarChartCardView`, `ILStatBreakdownCardView`
- [x] Create feature view `Views/ILStatsReminderCardView.swift`
- [x] Hide/restore the bottom nav on appear/disappear
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isStats`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILStatsEntity` + value types (`ILStatsPracticeKind`,
      `ILStatsMilestoneEntity`, `ILStatsWeekEntity`,
      `ILStatsPracticeShareEntity`, `ILStatsReminderEntity`)
- [x] Create `ILStatsStateModel` + per-card models (`ILStatsStreakModel`,
      `ILStatsTileModel`, `ILStatsFootnoteTone`, `ILStatsWeeklyChartModel`,
      `ILStatsBarModel`, `ILStatsMixItemModel`)
- [x] Create `ILStatsUseCase` / `ILStatsUseCaseImpl` — `getStats()` returns
      sample data (stub only; see Phase 3)
- [x] Create `ILStatsViewModel` (`Input -> Output`, `ILStatsNavEvent`) +
      Entity → StateModel mapping + formatting helpers (`makeBars`,
      `formatHoursDelta`, `formatTime`, `formatReminder`)
- [x] Create `ILStatsCoordinator` (`.goBack` wired; `.openReminder` TODO)
- [x] Wire `DIContainer.makeStatsUseCase/ViewModel/Coordinator`
- [x] Wire `ILProfileCoordinator.showStats()` + `ILProfileNavEvent.openStats`
- [x] Unit tests: `InnerLampTests/ILStatsViewModelTests.swift` (13 tests:
      mapping, empty/edge states, both nav events, formatting helpers),
      against `MockILStatsUseCase`

## Phase 3 — Data integration (pending, blocks feature completion)

- [ ] Define the stats data contract — backend API vs local-first store,
      request/response shapes, error cases

      > ⚠️ Not confirmed: the exact contract; the handoff README suggests
      > "local-first, then synced" but nothing is confirmed yet.

- [ ] Create `ILStatsDTO` + `ILStatsMapper` (only once the contract above
      is confirmed — never created speculatively "for later")
- [ ] Create `ILStatsRepository` protocol + implementation (local-first +
      sync, or remote, per the confirmed contract)
- [ ] Inject the repository into `ILStatsUseCaseImpl.init`
- [ ] Replace the stubbed `getStats()` body with the real repository call
- [ ] Map errors to feature-specific error cases
- [ ] Update `ILStatsViewModelTests` + add a mock repository to cover real
      success/failure paths
- [ ] Render `.failure` (error / offline) in `ILStatsViewController`
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Stats/README.md` (implementation
      notes, status table, known gaps, changelog)
- [ ] `Docs/Knowledge/features/stats.md` (OKF concept) — hold off until
      Phase 3 lands so the concept describes real end-to-end behavior
      instead of a stub. See `Docs/Specs/OKF.md`.

## Deferred (separate feature, not blocking Stats)

- Mindfulness bell reminder (`remind`) screen — the `.openReminder`
  destination. Separate, not-yet-built feature.
- Other entry points from the handoff (Home streak card, Journal detail
  "Xem tiến trình", Awards bottom button) — wiring those screens to Stats
  is separate work.
