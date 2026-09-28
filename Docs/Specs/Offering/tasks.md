# Tasks — Offering

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILOfferingViewController` + `ILOfferingReceiptViewController`
      extending `BaseViewController`
- [ ] `setupViews()`: offering (dedication card, amount options + custom input,
      dedication/temple fields, commitment note, payment button), receipt (kệ,
      details table, "Lưu ảnh" / "Về trang chủ")
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire amount/custom/payment/receipt actions to `Input`,
      render `Output.state`
- [ ] Visual QA against the design prototype (screens `offer`, `receipt`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILOfferingEntity` (pure business fields only)
- [ ] Create `ILOfferingStateModel` (UI state, no UIKit import)
- [ ] Create `ILOfferingUseCase` / `ILOfferingUseCaseImpl`:
      - amount selection + custom validation
      - `submitOffering(...)` — stub only (no confirmed contract)
      - `getReceipt(...)` — stub only (if a separate call is confirmed)
      - `ILOfferingError`
- [ ] Create `ILOfferingViewModel` (`Input -> Output`, `ILOfferingNavEvent`)
- [ ] Create `ILOfferingCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeOffering{UseCase,ViewModel,Coordinator}`
- [ ] Wire `TempleCoordinator` / `ProfileCoordinator` `showOffering()` + delegate
- [ ] Unit tests: `ILOfferingViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending, blocks feature completion)

> Contracts unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Resolve the Step-by-step Flow open items: payment endpoint/shape and
      whether the receipt is returned inline or via a separate call
- [ ] Define the offering/payment API contract (endpoint, amount/dedication/
      temple shape, payment-provider handoff, error cases)
- [ ] Create `ILOfferingDTO` + `ILOfferingMapper` (only after contract confirmed)
- [ ] Create the `Endpoint` conformance(s) under `Data/DataSources/Remote/`
- [ ] Create `ILOfferingRepository` protocol + `ILOfferingRepositoryImpl`
- [ ] Inject the repository into `ILOfferingUseCaseImpl.init`; replace the stubs
- [ ] Map network/HTTP errors to `ILOfferingError` cases
- [ ] Update `ILOfferingViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Offering/README.md`
- [ ] `Docs/Knowledge/features/offering.md` (OKF concept) — after Phase 3 lands

## Deferred (separate feature, not blocking Offering)

- Temple, Profile, payment-provider integration (shared concern).
