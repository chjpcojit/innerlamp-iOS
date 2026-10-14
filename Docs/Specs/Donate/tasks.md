# Tasks — Donate

Version: 1.1
Last updated: 2026-10-11
Status: Phases 1–2 implemented and build-verified; unit tests not yet run, device QA pending; Phase 3 blocks release

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILDonateViewController` extending `BaseViewController`
- [x] `setupViews()`: `ILStickyHeaderBand` + `ILNavBar` (close), form / transfer / thanks content
- [x] `setupConstraints()`: Auto Layout per design tokens; header inset in `viewDidLayoutSubviews`
- [x] `bindViewModel()`: wire amount / custom / message / action / change-amount / confirm / close to `Input`, render `Output.state`
- [x] Extract `ILDonateAmountGridView`, `ILDonateQRView`, `ILDonateInfoTableView`, `ILDonateThanksView` (feature `Views/`)
- [x] Add any missing tokens: `ILColors.qrBackground` added; CTA uses the existing `.gold` button variant (no gradient token — deviation from prototype)
- [x] Keyboard avoidance for the custom amount and message fields (via `BaseViewController`)
- [ ] Visual QA against the prototype (screen `paywall`)

## Phase 2 — Logic (Domain + mocked data)

- [x] Create `ILDonationAccountEntity`, `ILDonationTransferEntity`
- [x] Create `ILDonationAccountRepository` protocol (Domain)
- [x] Create `ILMockDonationAccountRepository` (Data, placeholder constants)
- [x] Create `ILDonateUseCase` / `ILDonateUseCaseImpl` (amount rules, sanitize, transfer)
- [x] Create `ILDonateStateModel` (no UIKit import)
- [x] Create `ILDonateViewModel` (`Input -> Output`, `ILDonateNavEvent`)
- [x] Create `ILDonateCoordinator` with `startModal()`
- [x] Add localization keys for all copy
- [x] Wire `DIContainer.makeDonate{UseCase,ViewModel,Coordinator}`
- [x] Wire `ILProfileCoordinator` `.openDonate` → `ILDonateCoordinator.startModal()`
- [x] Unit tests: `InnerLampTests/ILDonateViewModelTests.swift` (default 50.000₫, preset change, custom digits-only + 9-digit cap + grouping, below-minimum disabled, boundary 10.000, change amount keeps values, confirm → thanks, close event) and `ILDonateUseCaseTests.swift`
- [x] Never log the message body (AGENTS §7)
- [x] Record Assumptions (mock account/QR, note rule, no receipt, no API) in `Docs/Assumptions/Donate/` and Tech Debt (mock provider) in `Docs/Tech-Debt/Donate/` — bilingual, per AGENTS §10

## Phase 3 — Real account details (pending, blocks release)

> ⚠️ Not confirmed: real recipient, bank, account number, VietQR payload,
> transfer-note rule and receipt behavior.

- [ ] Obtain account details and note rule from the product owner
- [ ] Replace `ILMockDonationAccountRepository` (or add a real implementation)
- [ ] Decide receipt / message delivery (needs an API contract) or remove those UI lines
- [ ] Confirm App Store review acceptability
- [ ] Resolve the Assumption and Tech Debt entries (update status, never delete)

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Donate/README.md` (add its path to `membershipExceptions` in `project.pbxproj`, AGENTS §8)
- [x] Update `Presentation/Scenes/Profile/README.md` (`openDonate` done) and `Docs/Specs/Profile/` if its behavior doc changes
- [ ] `Docs/Knowledge/features/donate.md` (OKF concept) — after verification, via `okf-writer`

## Deferred (separate feature, not blocking Donate)

- Donation history, "Sổ công đức", temple offering ("Cúng dường").
