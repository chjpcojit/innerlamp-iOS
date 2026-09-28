# Tasks — Register

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILRegisterViewController` extending `BaseViewController`
- [ ] `setupViews()`: header, details table, group-size selector, note, confirm
      button
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire group-size / confirm / back to `Input`, render
      `Output.state`
- [ ] Visual QA against the design prototype (screen `register`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILRegisterEntity` (pure business fields only)
- [ ] Create `ILRegisterStateModel` (UI state, no UIKit import)
- [ ] Create `ILRegisterUseCase` / `ILRegisterUseCaseImpl`:
      - group-size label derivation
      - `register(...)` — stub only (no confirmed backend contract)
      - `ILRegisterError`
- [ ] Create `ILRegisterViewModel` (`Input -> Output`, `ILRegisterNavEvent`)
- [ ] Create `ILRegisterCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeRegister{UseCase,ViewModel,Coordinator}`
- [ ] Wire `EventsCoordinator.showRegister(event:)` + delegate conformance
- [ ] Unit tests: `ILRegisterViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending, blocks feature completion)

> Contract unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Define the register API contract (endpoint, request/response shape,
      capacity/error cases)
- [ ] Create `ILRegisterDTO` + `ILRegisterMapper` (only after contract confirmed)
- [ ] Create the `Endpoint` conformance under `Data/DataSources/Remote/`
- [ ] Create `ILRegisterRepository` protocol + `ILRegisterRepositoryImpl`
- [ ] Inject the repository into `ILRegisterUseCaseImpl.init`; replace the stub
- [ ] Map network/HTTP errors to `ILRegisterError` cases
- [ ] Update `ILRegisterViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Register/README.md`
- [ ] `Docs/Knowledge/features/register.md` (OKF concept) — after Phase 3 lands

## Deferred (separate feature, not blocking Register)

- Events.
