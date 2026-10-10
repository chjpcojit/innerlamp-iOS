# Tasks — Legal

Version: 1.0
Last updated: 2026-10-10
Status: not started — prospective; document text is bundled mock

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILLegalViewController` extending `BaseViewController`
- [ ] `setupViews()`: segmented control, title, effective line, sections card,
      contact card
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire segment / contact / retry / back to `Input`,
      render `Output.state`
- [ ] Extract `ILLegalSegmentedControl`, `ILLegalSectionView`,
      `ILLegalContactCardView` (feature `Views/`)
- [ ] Rebuild sections only when the document changes; scroll to top on switch
- [ ] Visual QA against the design prototype (screen `legal`)

## Phase 2 — Logic (Domain + bundled content)

- [ ] Create `ILLegalDocumentKind`, `ILLegalDocumentEntity`,
      `ILLegalSectionEntity`
- [ ] Create `ILLegalRepository` protocol + `ILLegalRepositoryImpl` (reads the
      existing `legal.*` keys; 6 terms / 5 privacy sections)
- [ ] Create `ILLegalStateModel` (no UIKit import)
- [ ] Create `ILLegalUseCase` / `ILLegalUseCaseImpl` (`loadDocument(kind:)`,
      `ILLegalError`)
- [ ] Create `ILLegalViewModel` (`Input -> Output`, `ILLegalNavEvent`, document
      cache)
- [ ] Create `ILLegalCoordinator(initial:)` + delegate protocol (`openContact`)
- [ ] Add any missing localization keys (title/section keys already exist)
- [ ] Wire `DIContainer.makeLegal{Repository,UseCase,ViewModel,Coordinator}`
- [ ] Wire `ILSettingsCoordinator.showLegal(_:)` for `.openTerms` /
      `.openPrivacy`
- [ ] Unit tests: `InnerLampTests/ILLegalViewModelTests.swift` (initial
      document, switch, section counts 6/5, load failure + retry, contact tap),
      mocking `ILLegalUseCase`
- [ ] Record Assumptions (mock text, effective line, account-deletion claim) in
      `Docs/Assumptions/Legal/` and Tech Debt (mock source; sign-up sheet and
      Legal each read `legal.*` separately) in `Docs/Tech-Debt/Legal/` —
      bilingual, per AGENTS §10

## Phase 3 — API integration (pending, blocks feature completion)

> ⚠️ Not confirmed: legal-document API contract (endpoint, versioning,
> effective date, language).

- [ ] Obtain the contract from the product owner
- [ ] Create `ILLegalDTO` + `ILLegalMapper` (only after the contract is
      confirmed)
- [ ] Create the `Endpoint` conformance (`Data/DataSources/Remote/`)
- [ ] Switch `ILLegalRepositoryImpl` from bundled text to `NetworkService`;
      decide the effective-date/version source
- [ ] Update tests for success/failure
- [ ] Resolve the Assumption and Tech Debt entries (update status, never delete)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Legal/README.md` (add its path to
      `membershipExceptions` in `project.pbxproj`, AGENTS §8)
- [ ] `Docs/Knowledge/features/legal.md` (OKF concept) — after Phase 3, via
      `okf-writer`

## Deferred (separate feature, not blocking Legal)

- Settings (entry rows), SignUp legal sheet, Contact Support.
