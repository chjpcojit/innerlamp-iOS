# Tasks — Compose

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILComposeViewController` extending `BaseViewController`
- [ ] `setupViews()`: header (Đóng / "Chia sẻ" / "Đăng"), author + audience
      rotator, composer, attachment actions, tag chips, publish button
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire audience/attach/tag/publish/close to `Input`,
      render `Output.state`
- [ ] Visual QA against the design prototype (screen `compose`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILComposeEntity` (pure business fields only)
- [ ] Create `ILComposeStateModel` (UI state, no UIKit import)
- [ ] Create `ILComposeUseCase` / `ILComposeUseCaseImpl`:
      - audience cycling
      - `publish(post:)` — stub only (no confirmed backend contract)
      - `ILComposeError`
- [ ] Create `ILComposeViewModel` (`Input -> Output`, `ILComposeNavEvent`)
- [ ] Create `ILComposeCoordinator` (modal) + delegate protocol
- [ ] Wire `DIContainer.makeCompose{UseCase,ViewModel,Coordinator}`
- [ ] Wire `SanghaCoordinator.openCompose` → `presentCompose()`
- [ ] Unit tests: `ILComposeViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending, blocks feature completion)

> Contract unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Define the publish-post API contract (endpoint, audience/tag/attachment
      shape, error cases)
- [ ] Create `ILComposeDTO` + `ILComposeMapper` (only after contract confirmed)
- [ ] Create the `Endpoint` conformance under `Data/DataSources/Remote/`
- [ ] Create `ILComposeRepository` protocol + `ILComposeRepositoryImpl`
- [ ] Inject the repository into `ILComposeUseCaseImpl.init`; replace the stub
- [ ] Map network/HTTP errors to `ILComposeError` cases
- [ ] Update `ILComposeViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Compose/README.md`
- [ ] `Docs/Knowledge/features/compose.md` (OKF concept) — after Phase 3 lands

## Deferred (separate feature, not blocking Compose)

- Sangha, Post.
