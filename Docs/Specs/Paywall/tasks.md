# Tasks — Paywall

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILPaywallViewController` extending `BaseViewController`
- [ ] `setupViews()`: dark backdrop, title + benefits, 3 plan radios, CTA +
      note, dismiss link
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire plan selection / CTA / dismiss to `Input`, render
      `Output.state`
- [ ] Visual QA against the design prototype (screen `paywall`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILPaywallEntity` (pure business fields only)
- [ ] Create `ILPaywallStateModel` (UI state, no UIKit import)
- [ ] Create `ILPaywallUseCase` / `ILPaywallUseCaseImpl`:
      - CTA/note derivation per plan
      - `loadPlans()` / `purchase(plan:)` — stubs only (StoreKit unconfirmed)
- [ ] Create `ILPaywallViewModel` (`Input -> Output`, `ILPaywallNavEvent`)
- [ ] Create `ILPaywallCoordinator`
- [ ] Wire `DIContainer.makePaywall{UseCase,ViewModel,Coordinator}`
- [ ] Wire `ProfileCoordinator.showPaywall()`
- [ ] Unit tests: `ILPaywallViewModelTests.swift` (mock UseCase)

## Phase 3 — StoreKit integration (pending, blocks feature completion)

> Products unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm StoreKit product identifiers, price points, trial eligibility,
      and entitlement storage/verification
- [ ] Create `ILPaywallRepository` protocol + `ILPaywallRepositoryImpl` (StoreKit)
- [ ] Inject the repository into `ILPaywallUseCaseImpl.init`; replace the stubs
- [ ] Map StoreKit errors to feature error cases
- [ ] Update `ILPaywallViewModelTests` + add a mock repository
- [ ] Manual test with StoreKit configuration / sandbox

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Paywall/README.md`
- [ ] `Docs/Knowledge/features/paywall.md` (OKF concept) — after Phase 3

## Deferred (separate feature, not blocking Paywall)

- Profile, entitlement enforcement (shared concern), Receipt (Offering).
