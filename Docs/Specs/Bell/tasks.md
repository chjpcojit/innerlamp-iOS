# Tasks — Bell

Version: 1.0
Last updated: 2026-09-27
Status: complete — full in-memory practice tool (no network, no persistence yet)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer; there is no Phase 3 (API).

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILBellViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: strike pad, preset chips, mode
      segmented control, rate card, action bar — per design handoff (`--il-med-*`
      tokens)
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILBellChipView`, `ILBellModeSegmentedView`,
      `ILBellPadView`, `ILBellRateCardView`, `ILBellActionBarView`
- [x] Haptic feedback per strike; hide/show bottom nav
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `bell`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILBellEntity` + `ILBellMode` + `ILBellPreset`
- [x] Create `ILBellStateModel` (Presentation-side UI state, no UIKit import)
- [x] Create `ILBellUseCase` / `ILBellUseCaseImpl` (pure rules — presets,
      mode/every selection, rate clamping, strikes, auto-bell milestone,
      reset/run/roll, interval computation)
- [x] Add `Core/Audio/ILPracticeSoundPlaying` + `ILPracticeSoundPlayer`
      (`AVAudioPlayer` pool) + bundled `bell_strike.m4a` / `mo_strike.m4a` /
      `bead_click.m4a`
- [x] Create `ILBellViewModel` (`Input -> Output`, `ILBellNavEvent`, steady
      rhythm `Timer` + `DispatchWorkItem` roll, audio routing)
- [x] Create `ILBellCoordinator` (leaf — `.goBack` → pop + finish)
- [x] Wire `DIContainer.makeBellUseCase/ViewModel/Coordinator`
- [x] Wire `ILHomeCoordinator.showBell()` via `ILHomeNavEvent.openBell`
- [x] Unit tests: `InnerLampTests/ILBellViewModelTests.swift` (12 ViewModel
      tests + 11 `ILBellUseCaseImpl` tests in the same file, plus
      `MockILBellUseCase` / `MockILPracticeSoundPlayer`)

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Persistence & extras (pending)

- [ ] Add local persistence for session state (mode/preset/rhythm/counters) once
      a real need exists — currently memory-only
- [ ] Add a per-session volume / sound picker (see ⚠️ in `requirements.md`)
- [x] `InnerLamp/Presentation/Scenes/Bell/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/bell.md` (OKF concept) — see `Docs/Specs/OKF.md`
