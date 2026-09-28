# Tasks — LunarCalendar

Version: 1.0
Last updated: 2026-09-27
Status: complete (Phase 1–2); no API phase

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer — all data is computed locally via
> `ILLunarCalendar`.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILLunarCalendarViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header ✕ + hairline, ‹ › pager bar,
      month carousel, day-info card, upcoming rows — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILLunarCalendarPagerBarView`,
      `ILLunarCalendarMonthCarouselView`, `ILLunarCalendarMonthCardView`,
      `ILLunarCalendarDayInfoCardView`
- [x] Add shared `ILChevronCircleButton`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `cal`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILLunarCalendarEntity` + day/month entities + `ILLunarCalendarDayCategory`
- [x] Create `ILLunarCalendarStateModel` + day/month/upcoming models
- [x] Create `ILLunarCalendarUseCase` / `ILLunarCalendarUseCaseImpl` (6-month
      build, selectDay, upcomingSpecialDays — pure computation)
- [x] Create `ILLunarCalendarViewModel` (`Input -> Output`, `ILLunarCalendarNavEvent`,
      page clamping, day selection, Entity→StateModel mapping)
- [x] Create `ILLunarCalendarCoordinator` (leaf — `.close` pop+finish)
- [x] Wire `DIContainer.makeLunarCalendarUseCase/ViewModel/Coordinator`
- [x] Wire `ILHomeCoordinator.showLunarCalendar()` via `ILHomeNavEvent.openLunarCalendar`
- [x] Unit tests: `ILLunarCalendarViewModelTests` (10) + `ILLunarCalendarUseCaseTests`
      (9, real calendar — Tết 10/2/2024, Trung Thu 17/9/2024)

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Content & extras (pending)

- [ ] Confirm the per-day day-card content source (Buddhist-event API vs static
      copy) — see ⚠️ in `requirements.md`
- [ ] Confirm the fast-day convention for 29-day months (30 vs 29) — see ⚠️ in
      `requirements.md`
- [ ] Wire the "upcoming" rows to bell reminders + temple events if those
      become in-scope
- [x] `InnerLamp/Presentation/Scenes/LunarCalendar/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/lunar-calendar.md` (OKF concept) — see
      `Docs/Specs/OKF.md`
