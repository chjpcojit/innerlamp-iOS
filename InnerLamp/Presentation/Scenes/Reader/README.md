# Reader

## Overview

"Tụng kinh" screen (`reader` in the design handoff `Docs/InnerLamp project/`): a scrolling,
line-by-line chant text. Header = back + sutra title + status ("Đang tụng · narrator" / paused /
text-only) + "Aa"; under it the "Tự cuộn" toggle, "Màn hình luôn sáng" note and tap hint; the "Aa"
button reveals a panel with 4 font sizes and 3 backgrounds (Mặc định / Vàng cát / Đen OLED). The
list shows the shared "KHAI KINH" opening and the sutra body in headed sections, with ◉ (bell) /
• (wooden fish) cues, an optional English gloss and the current line highlighted. Bottom: progress
(audio sutras only), −10s / play-pause / +10s, and pace chips 1x / 1.2x / 1.5x. Leaf screen; only
event is `.back`. Opened by `ILSutraDetailCoordinator` and `ILLibraryCoordinator`.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILReaderEntity.swift` | Done | cue, line, section, sutra, entity (line index, speed, playing, accumulator). |
| Domain — UseCase | `ILReaderUseCase.swift` | Done | Mock 11-sutra catalog (text for Pháp Cú + Tâm Kinh), seek/speed/advance/progress. |
| Presentation — StateModel | `ILReaderStateModel.swift` | Done | Rows, labels, UI preference indexes, speed chips. |
| Presentation — ViewModel | `ILReaderViewModel.swift` | Done | 11 `Input`s + injectable tick publisher. |
| Presentation — ViewController | `ILReaderViewController.swift` | Done (not device-checked) | Table, auto-scroll, per-theme forced appearance, keep-awake. |
| Presentation — Views | `Views/*` | Done | Line/heading cells, auto-scroll row, settings panel, controls, palette. |
| Presentation — Coordinator | `ILReaderCoordinator.swift` | Done | `.back` → pop + finish. |
| Data — DTO + Mapper | — | N/A | No confirmed API contract. |
| Shared tokens | `ILColors.Reader`, `ILTypography`, `ILMetrics` | Done | 6 new `ILReader*` color assets. |
| Tests | `ILReaderViewModelTests`, `ILReaderUseCaseTests` | Written, not run | Test target did not build in the authoring environment. |

## Known gaps

- Timer-driven highlight, no audio — TD-Reader-001.
- Duplicated mock catalog / text for 2 sutras only — TD-Reader-002.
- Preferences not persisted — TD-Reader-003.
- Always starts at line 0 (no chapter/part entry point).
- Assumptions: AS-Reader-001…003 (`Docs/Assumptions/Reader/`).
- Not yet checked on a physical device (layout, dark mode, themes).

## Changelog

- 2026-09-26 — initial build (verse view + playback bar).
- 2026-10-03 — redesigned to the scrolling chant view of the refreshed handoff; removed share/download/font-size/player events, `ILReaderVerseView`, `ILReaderPlaybackBarView`.
