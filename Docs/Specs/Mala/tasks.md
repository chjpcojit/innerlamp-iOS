# Tasks — Mala

Version: 1.0
Last updated: 2026-09-27
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

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Persistence & extras (pending)

- [ ] Add local persistence (Core Data / UserDefaults) and sync with the Home
      bead counter — see ⚠️ in `requirements.md`
- [ ] Add a user-facing volume / sound picker
- [x] `InnerLamp/Presentation/Scenes/Mala/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/mala.md` (OKF concept) — see `Docs/Specs/OKF.md`
