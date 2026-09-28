# Tasks — Share

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILShareViewController` extending `BaseViewController`
- [ ] `setupViews()`: card preview (verse + kicker + lamp motif), 3 background
      chips, 4 destination buttons
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire background/destination taps + close to `Input`,
      render `Output.state`
- [ ] Visual QA against the design prototype (screen `share`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILShareEntity` (pure business fields only)
- [ ] Create `ILShareStateModel` (UI state, no UIKit import)
- [ ] Create `ILShareUseCase` / `ILShareUseCaseImpl`:
      - background selection (pure logic)
      - `copyToClipboard` (local)
      - `shareToCommunity` — stub only (behavior unconfirmed)
- [ ] Create `ILShareViewModel` (`Input -> Output`, `ILShareNavEvent`)
- [ ] Create `ILShareCoordinator` (modal presentation, dismiss on ✕)
- [ ] Wire `DIContainer.makeShare{UseCase,ViewModel,Coordinator}`
- [ ] Wire `ReaderCoordinator` / `ArticleCoordinator` "Chia sẻ" actions
- [ ] Unit tests: `ILShareViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending; only for the "Đạo tràng" destination)

> Unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm whether "Đạo tràng" posts via an API, and its contract
- [ ] If API: create `ILShareRepository` + `ILShareRepositoryImpl` + DTO/Mapper
      + Endpoint; inject into `ILShareUseCaseImpl`; replace the stub
- [ ] Map network/HTTP errors to feature error cases
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Share/README.md`
- [ ] `Docs/Knowledge/features/share.md` (OKF concept) — after Phase 3 resolves

## Deferred (separate feature, not blocking Share)

- Reader, Article, Sangha/Post (community feed).
