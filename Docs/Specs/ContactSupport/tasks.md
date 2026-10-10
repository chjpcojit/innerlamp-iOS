# Tasks — ContactSupport

Version: 1.0
Last updated: 2026-10-10
Status: not started — prospective; channels and submit API are mocked

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILContactSupportViewController` extending `BaseViewController`
- [ ] `setupViews()`: heading, channel card, form card / sent card, FAQ shortcut
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire channel / topic / message / submit / new-request /
      FAQ taps to `Input`, render `Output.state`
- [ ] Extract `ILSupportChannelRowView`, `ILSupportRequestFormView`,
      `ILSupportSentCardView` (feature `Views/`)
- [ ] Keyboard avoidance for the message field
- [ ] Visual QA against the design prototype (screen `contact`)

## Phase 2 — Logic (Domain + stubbed behavior)

- [ ] Create `ILSupportChannelEntity`, `ILSupportTopic`,
      `ILSupportRequestEntity`, `ILSupportReceiptEntity`
- [ ] Create `ILContactSupportStateModel` (no UIKit import)
- [ ] Create `ILSupportRepository` protocol (Domain; no implementation yet)
- [ ] Create `ILContactSupportUseCase` / `ILContactSupportUseCaseImpl`:
      - `loadChannels()` — mock constants
      - `validate(message:)` — trimmed length ≥ 10
      - `submit(_:)` — stub only (local request code; no contract)
- [ ] Create `ILContactSupportViewModel` (`Input -> Output`,
      `ILContactSupportNavEvent`)
- [ ] Create `ILContactSupportCoordinator` + delegate protocol (`openHelp`);
      system URL opening with unavailable-channel feedback
- [ ] Add localization keys for all copy (heading, topics, errors, sent card)
- [ ] Wire `DIContainer.makeContactSupport{UseCase,ViewModel,Coordinator}`
- [ ] Wire `ILSettingsCoordinator.showContactSupport()` and the delegates of
      Help and Legal
- [ ] Identify the signed-in phone source for the reply note (see design ⚠️)
- [ ] Unit tests: `InnerLampTests/ILContactSupportViewModelTests.swift`
      (default topic, topic change, short-message error + clear on edit, submit
      success → receipt, submit failure keeps message, new request resets),
      mocking `ILContactSupportUseCase`
- [ ] Mask the phone number and never log the message body (AGENTS §7)
- [ ] Record Assumptions (mock channels, stub submit, reply copy) in
      `Docs/Assumptions/ContactSupport/` and Tech Debt (stubbed submit) in
      `Docs/Tech-Debt/ContactSupport/` — bilingual, per AGENTS §10

## Phase 3 — API integration (pending, blocks feature completion)

> ⚠️ Not confirmed: support-request API contract (endpoint, payload,
> request-code format, auth) and the real channel values.

- [ ] Obtain the support-request contract and the real email / hotline / Zalo
      values from the product owner
- [ ] Create `ILSupportRequestDTO` + `ILSupportReceiptDTO` + mappers
- [ ] Create the `Endpoint` conformance (`Data/DataSources/Remote/`)
- [ ] Create `ILSupportRepositoryImpl` wrapping `NetworkService`
- [ ] Inject the repository into `ILContactSupportUseCaseImpl.init`; replace the
      stub body
- [ ] Map network errors to `ILContactSupportError` (offline, server, rate limit)
- [ ] Update `ILContactSupportViewModelTests` + mock repository for real
      success/failure
- [ ] Resolve the Assumption and Tech Debt entries (update status, never delete)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/ContactSupport/README.md` (add its path to
      `membershipExceptions` in `project.pbxproj`, AGENTS §8)
- [ ] `Docs/Knowledge/features/contact-support.md` (OKF concept) — after
      Phase 3, via `okf-writer`

## Deferred (separate feature, not blocking ContactSupport)

- Settings (entry row), Help, Legal, Notifications (reply delivery).
