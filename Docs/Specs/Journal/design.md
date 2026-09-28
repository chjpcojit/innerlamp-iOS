# Design — Journal

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-first (sync unconfirmed)

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Journal follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**cross-section feature** with three screens (list → write, list → entry →
write) reached from Home, Profile, and Stats. It is **local-first** per the
design: entries are stored locally (Core Data) with sync deferred. A single
coordinator owns all three screens.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILJournalEntity.swift` | Pure business fields: id, date, solar/lunar date parts, title, body, mood, dedication, tags, practice items. |
| Domain / UseCase | `Domain/UseCases/Journal/ILJournalUseCase.swift` | CRUD + weekly-duration aggregation: `listEntries()`, `getEntry(id:)`, `saveEntry(...)`, `weeklyMinutes()`. |
| Domain / Repository | `Domain/Repositories/ILJournalRepository.swift` | `list/get/save` over the local store; `sync()` stub until backend confirmed. Entity in/out. |
| Data / Repository | `Data/Repositories/ILJournalRepositoryImpl.swift` | Core Data-backed; later a sync path. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Journal/ILJournalStateModel.swift` | UI-only state: entry list, weekly chart, write form (body, tags, counter), entry detail. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Journal/ILJournalViewModel.swift` | `Input -> Output`; owns `ILJournalNavEvent` (openWrite, openEntry, openLunarCalendar, openStats, openItem). |
| Presentation / Coordinator | `Presentation/Scenes/Journal/ILJournalCoordinator.swift` | Pushes the list/write/entry controllers; forwards nav events to the owning section. |
| Presentation / ViewController | `Presentation/Scenes/Journal/ILJournalViewController.swift` (+ `ILJournalWriteViewController`, `ILJournalEntryViewController`) | Three screens per `BaseViewController`. |

## Navigation flow

```
HomeCoordinator / ProfileCoordinator / StatsCoordinator
  └─ (tap "Nhật ký" / journal entry point) → showJournal() → ILJournalCoordinator
       push ILJournalViewController (list)
         (tap entry) → push ILJournalEntryViewController
             (tap "Sửa"/"Viết thêm") → push ILJournalWriteViewController
         (tap "Ghi lại hôm nay") → push ILJournalWriteViewController
         (tap "Lịch âm") → openLunarCalendar
         (tap "Xem tiến trình") → openStats
```

## Data flow

Local CRUD, no multi-call sequence → Step-by-step Flow not required:

1. List: `listEntries()` + `weeklyMinutes()` from the local repository.
2. Write: `saveEntry(...)` → local store → back to list.
3. Entry: `getEntry(id:)` → local store → render; practice items navigate out.

## Deliberately stubbed for now

`ILJournalRepository.sync()` is a one-line stub (`print("TODO: …")`) until a sync
backend contract exists — see `requirements.md` Pending. All local CRUD methods
are real (Core Data). The local-first storage can be fully built without the
sync contract (`tasks.md` Phase 2 vs Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screens `journal`, `write`, `entry`, and `Mo-ta-tinh-nang.md` §5 "Nhật ký & tiến
trình".
