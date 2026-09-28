# Tasks — Reminder

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-only

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILReminderViewController` extending `BaseViewController`
- [ ] `setupViews()`: intro, hour steppers, 7 weekday buttons, extra-schedule
      rows, save button
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire hour/day/save to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screen `remind`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILReminderEntity` (pure business fields only)
- [ ] Create `ILReminderStateModel` (UI state, no UIKit import)
- [ ] Create `ILReminderUseCase` / `ILReminderUseCaseImpl`:
      - summary derivation ("mỗi ngày" / "N ngày mỗi tuần")
      - contextual hour hint
      - `save(reminder:)`
- [ ] Create `ILReminderScheduler` protocol + `ILReminderSchedulerImpl`
      (UNUserNotificationCenter + UserDefaultsService)
- [ ] Create `ILReminderViewModel` (`Input -> Output`, `ILReminderNavEvent`)
- [ ] Create `ILReminderCoordinator`
- [ ] Wire `DIContainer.makeReminder{UseCase,ViewModel,Coordinator,Scheduler}`
- [ ] Wire Stats/Profile/Home coordinators' `showReminder()`
- [ ] Unit tests: `ILReminderViewModelTests.swift` + `ILReminderUseCaseTests.swift`
      (mock scheduler; summary/hint derivation)

## Phase 3 — API integration

- Not applicable — local-only (system notifications + local storage). No backend.

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Reminder/README.md`
- [ ] `Docs/Knowledge/features/reminder.md` (OKF concept)

## Deferred (separate feature, not blocking Reminder)

- Bell (chuông mõ), Settings schedule card, Stats reminder card.
