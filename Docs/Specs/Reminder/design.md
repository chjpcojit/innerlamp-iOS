# Design — Reminder

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-only, no backend

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Reminder follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**cross-section screen** reached from Stats, Profile, and Home. It is
local-only: the schedule is persisted locally and handed to the system
notification service, so there is **no Data / network layer** — no DTO, Mapper,
or Repository.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILReminderEntity.swift` | Pure business fields: hour, minute, enabled weekdays, extra schedule toggles. |
| Domain / UseCase | `Domain/UseCases/Reminder/ILReminderUseCase.swift` | Validation/derivation (summary text, contextual hint) + `save(reminder:)` delegating to a local scheduler protocol. |
| Domain / Scheduler | `Domain/Repositories/ILReminderScheduler.swift` | `schedule(_:)` / `cancel()` abstraction over the system notification service. |
| Data / Scheduler | `Data/DataSources/Local/ILReminderSchedulerImpl.swift` | Wraps `UNUserNotificationCenter` + `UserDefaultsService`/local store. |
| Presentation / State | `Presentation/Scenes/Reminder/ILReminderStateModel.swift` | UI-only state: hour/minute, weekday flags, summary text, hint text. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Reminder/ILReminderViewModel.swift` | `Input -> Output`; owns `ILReminderNavEvent` (back). |
| Presentation / Coordinator | `Presentation/Scenes/Reminder/ILReminderCoordinator.swift` | Pushes `ILReminderViewController`. |
| Presentation / ViewController | `Presentation/Scenes/Reminder/ILReminderViewController.swift` | Hour steppers, weekday buttons, extra-schedule rows, save button. |

## Navigation flow

```
StatsCoordinator / ProfileCoordinator / HomeCoordinator
  └─ (tap "Chuông nhắc" card) → showReminder() → ILReminderCoordinator
       push ILReminderViewController
       (tap "Lưu chuông nhắc") → schedule + confirm, stay
       (tap back) → pop
```

## Data flow

Local-only, no network → no Step-by-step Flow section needed:

1. `save` → `ILReminderUseCase.save(reminder:)` → `ILReminderScheduler.schedule(_:)`
   (UNUserNotificationCenter) + persist to `UserDefaultsService` → confirm.

## Deliberately stubbed for now

None — no network dependency exists. `ILReminderScheduler.schedule(_:)` wraps
the real system notification API.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `remind`, and `Mo-ta-tinh-nang.md` §4 "Chuông nhắc (Chuông tỉnh thức)".
