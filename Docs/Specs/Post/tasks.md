# Tasks — Post

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer today; Phase 3 tracks replacing the
> static catalog with a real community API.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILPostViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header, post card, comments section,
      composer bar (pinned bottom) — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILPostCardView`, `ILPostCommentListView`,
      `ILPostComposerBarView`
- [x] Add `ILTypography.postBody` / `bodyMedium` / `labelMedium` +
      `ILMetrics.commentIndent`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `post`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILPostEntity` + `ILPostItemEntity` + `ILPostCommentEntity`
- [x] Create `ILPostStateModel` + `ILPostAuthorTone` + `ILPostCommentModel`
- [x] Create `ILPostUseCase` / `ILPostUseCaseImpl` (catalog, fallback-by-id,
      toggleLike — pure logic)
- [x] Create `ILPostViewModel` (`Input -> Output`, `ILPostNavEvent`,
      `postID` parameter, `now` clock injection, format helpers)
- [x] Create `ILPostCoordinator` (leaf — `.back` pop+finish; `.share` TODO)
- [x] Wire `DIContainer.makePostUseCase/ViewModel/Coordinator`
- [x] Wire `ILSanghaCoordinator.showPost(_:)` via `ILSanghaNavEvent.openPost(id:)`
- [x] Unit tests: `InnerLampTests/ILPostViewModelTests.swift` (8 tests) — state
      map, comment map, toggle like, nav back/share, format helpers

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the posts/comments API contract(s) (see `requirements.md`
> Pending). Everything below is blocked until a contract exists.

- [ ] Define the community posts/comments API contract(s) with the backend team
- [ ] Create `ILPostDTO` + `ILPostMapper` (once the contract is confirmed)
- [ ] Create `PostEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILPostRepository` protocol + `ILPostRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the static catalog in `ILPostUseCaseImpl` with real data
- [ ] Persist/submit likes to the server
- [ ] Implement comment submission (composer bar → repository call)
- [ ] Update `ILPostViewModelTests` + add a mock repository
- [ ] Visual QA on simulator/device (scroll, composer, dark mode)
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Share destination (pending, separate scope)

- [ ] Build the Share screen (`share`, 3 card styles) and wire `.share` to it
- [ ] Update `InnerLamp/Presentation/Scenes/Post/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Post/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/post.md` (OKF concept) — hold off until the
      community API (Phase 3) lands. See `Docs/Specs/OKF.md`.
