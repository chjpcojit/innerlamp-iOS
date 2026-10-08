# Talks

## Overview

"Pháp thoại" list screen — every Dharma talk in the catalog. Opened from Library's "Pháp thoại"
quick-access tile. Sticky header (nav bar + talk count) over a scrolling list of talk cards;
tapping a card opens `Talk` (the detail/player screen). Owned by `ILLibraryCoordinator`;
`ILTalksCoordinator` manages its own stack. Spec: `Docs/Specs/Talks/`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILTalksEntity.swift` | Done | Media type, filter, list item. |
| Presentation — StateModel | `ILTalksStateModel.swift` | Done | Filter chips with counts, eyebrow, meta, resume progress. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract) | Catalog is mock data. |
| Domain — UseCase | `ILTalksUseCase.swift` | Partial | 8-talk mock catalog + pure `filter`. TODO: repository. |
| Presentation — ViewModel | `ILTalksViewModel.swift` | Done | 4 Inputs. |
| Presentation — ViewController | `ILTalksViewController.swift` | Done | Visual QA pending (not run on device). |
| Presentation — Coordinator | `ILTalksCoordinator.swift` | Done | `.back`, `.openTalk` → `ILTalkCoordinator`. |
| Tests | `ILTalksViewModelTests.swift` | Written, not run | XCTest needs a device. |
| Wiring | `DIContainer` + `ILLibraryCoordinator` | Done | `makeTalks*`, `showTalks()`. |

## Navigation events

- `back` — pop + `finish()`.
- `openTalk(id:)` — push `Talk`.

## Known gaps

- Only `talk.vulan.hieu` has a real detail; video/text variants not built (TD-Talks-002).
- No search/pagination; no loading/error states (synchronous mock).
- Matches design handoff screen `talks` (updated 2026-10-05).

## Changelog

- 2026-10-05 — initial implementation
