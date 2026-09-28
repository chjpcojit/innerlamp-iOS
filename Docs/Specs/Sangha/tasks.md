# Tasks — Sangha

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock data. Checked items reflect
> what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILSanghaViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: pinned title + find-sangha link,
      live-session card, two quick-action chips, community card, post feed —
      per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILSanghaLiveSessionCardView`,
      `ILSanghaCommunityCardView`, `ILSanghaPostCardView`, `ILSanghaPostListView`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `sangha`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILSanghaEntity` + `ILSanghaLiveSessionEntity` +
      `ILSanghaCommunityEntity` + `ILSanghaPostEntity`
- [x] Create `ILSanghaStateModel` + section models
- [x] Create `ILSanghaUseCase` / `ILSanghaUseCaseImpl` (`getSangha()` — mock)
- [x] Create `ILSanghaViewModel` (`Input -> Output`, `ILSanghaNavEvent`, 6
      cases, Entity→StateModel mapping + format helpers)
- [x] Create `ILSanghaCoordinator` (Events/Temple/Post wired; find-sangha/
      sit-together/compose TODO)
- [x] Wire `DIContainer.makeSanghaUseCase/ViewModel/Coordinator`
- [x] Wire `ILMainTabCoordinator` to use `ILSanghaCoordinator` as the Sangha tab
- [x] Unit tests: `InnerLampTests/ILSanghaViewModelTests.swift` (13 tests) —
      one per Input, state mapping, formatting helpers

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the sangha/community API contract(s) (see `requirements.md`
> Pending). Everything below is blocked until a contract exists.

- [ ] Define the community API contract(s) with the backend team (live count,
      community, feed)
- [ ] Create `ILSanghaDTO` + `ILSanghaMapper` (once the contract is confirmed)
- [ ] Create `SanghaEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILSanghaRepository` protocol + `ILSanghaRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the mock data in `ILSanghaUseCaseImpl.getSangha()` with real
      repository calls
- [ ] Design real-time live count (polling / socket) if needed
- [ ] Add post engagement (like / reply) actions
- [ ] Add loading / error / offline states
- [ ] Update `ILSanghaViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Unbuilt destinations (pending, separate scope)

- [ ] Build the find-sangha screen and wire `.openFindSangha`
- [ ] Wire `.startSitting` → MeditationSetup (Lamp flow)
- [ ] Build the compose modal and wire `.openCompose`
- [ ] Update `InnerLamp/Presentation/Scenes/Sangha/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Sangha/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/sangha.md` (OKF concept) — hold off until the
      community API (Phase 3) lands. See `Docs/Specs/OKF.md`.
