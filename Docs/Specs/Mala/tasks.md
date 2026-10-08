# Tasks — Mala

Version: 1.1
Last updated: 2026-10-03
Status: complete (Phase 1–2); persistence pending

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer; there is no Phase 3 (API).

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILMalaViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: immersive background, count display +
      progress, strand, action bar — per design handoff (`--il-med-*` tokens)
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Add shared components: `ILImmersiveBackgroundView`, `ILMalaStrandView`,
      `ILMalaCountDisplayView`, `ILImmersiveActionBarView`
- [x] Haptic feedback per milestone; hide/show bottom nav
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `mala`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILMalaEntity` + `ILMalaMilestone`
- [x] Create `ILMalaStateModel`
- [x] Create `ILMalaUseCase` / `ILMalaUseCaseImpl` (advanceBead wrap, resetBeads,
      milestone — pure logic)
- [x] Create `ILMalaViewModel` (`Input -> Output`, `ILMalaNavEvent`, audio via
      `ILPracticeSoundPlaying`)
- [x] Create `ILMalaCoordinator` (leaf — `.goBack` pop+finish)
- [x] Wire `DIContainer.makeMalaUseCase/ViewModel/Coordinator`
- [x] Wire `ILHomeCoordinator.showMala()` via `ILHomeNavEvent.openMala`
- [x] Unit tests: `ILMalaViewModelTests` (7) + `ILMalaUseCaseTests` (7, in the
      same file)

## Phase 2b — Redesign (v1.1, `Docs/InnerLamp icon consistency/`)

- [x] Header with "Xong" action + "Vòng N · biến x / goal" subtitle; remove big
      count display, hint and footnote; single "Bắt đầu lại" button
- [x] Goal chips 21 / 54 / 108 (`selectGoal`), progress bar (`ILMalaProgressBarView`
      replaces `ILMalaCountDisplayView`)
- [x] Red cord + rotated/shaded wooden beads in `ILMalaStrandView`
- [x] "Tròn N biến" popup (`ILMalaCompletionView`) + `startNextRound`
- [x] Update unit tests (view model + use case) for the new rules
- [ ] Run the updated tests — the `InnerLampTests` target currently fails to build
      (unresolved `GRPCProtobuf` in `GRPCAuthInterceptorTests`, unrelated to Mala)
- [ ] Wood-grain stripes on beads — see `Docs/Tech-Debt/Mala/TD-Mala-001-bead-grain-texture.md`

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Persistence & extras (pending)

- [ ] Add local persistence (Core Data / UserDefaults) and sync with the Home
      bead counter — see ⚠️ in `requirements.md`
- [ ] Add a user-facing volume / sound picker
- [x] `InnerLamp/Presentation/Scenes/Mala/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/mala.md` (OKF concept) — see `Docs/Specs/OKF.md`
