# Design — Post

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full post detail with static catalog + in-memory like;
Share not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Post ("Bài đăng đạo tràng") follows MVVM-C + Clean Architecture per `AGENTS.md`.
It is a **leaf screen** — `ILPostCoordinator` has no delegate. It is created by
`ILSanghaCoordinator` (tapping a card in the "Chia sẻ của bạn đồng tu" feed →
`ILSanghaNavEvent.openPost(id:)`) and pushed onto the Sangha tab's
`BaseNavigationController`. It is parameterized by a `postID` (with fallback to
the first catalog post when the id is unknown). There is **no network** — the
UseCase returns a static catalog.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILPostEntity.swift` | `ILPostItemEntity` (author, initials, postedAt, tag, body, likeCount, commentCount, communityName, communityMemberCount), `ILPostCommentEntity` (with `parentID` for threading), `ILPostEntity` (post, comments, `isLiked`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Post/ILPostUseCase.swift` | `getInitialState(postID:)` (static 5-post catalog + 3 comments, fallback to first), `toggleLike(in:)` (in-memory). Pure logic, no network/disk. |
| Presentation / State | `Presentation/Scenes/Post/ILPostStateModel.swift` | UI-only state: community header, author + `ILPostAuthorTone`, meta text, body, like/comment counts (formatted), `ILPostCommentModel` (time text, like label, depth). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Post/ILPostViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILPostNavEvent` (`.back`, `.share`); Entity→StateModel mapping + helpers `formatCount` / `formatRelativeTime` / `tone(for:)`. |
| Presentation / Coordinator | `Presentation/Scenes/Post/ILPostCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop + `finish()`; `.share` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Post/ILPostViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; hides bottom nav. |
| Feature-scoped views | `Presentation/Scenes/Post/Views/ILPostCardView.swift`, `ILPostCommentListView.swift`, `ILPostComposerBarView.swift` | Post card, comment list, and (UI-only) composer bar. |
| Shared tokens | `DesignSystem/Tokens/ILTypography.swift` + `ILMetrics.swift` | `postBody`, `bodyMedium`, `labelMedium`, `ILMetrics.commentIndent` (22). |

## Navigation flow

```
ILSanghaCoordinator (Sangha tab)
  └─ showPost(id) → ILPostCoordinator                (leaf, no delegate)
       push ILPostViewController
       (.back) → pop + finish()
       (.share) → TODO (Share screen not built)
```

## Data flow

1. `ILPostViewModel` loads `useCase.getInitialState(postID:)` and maps the post
   + comments to `ILPostStateModel` (relative time, formatted counts, avatar
   tone derived from author name, comment depth from `parentID`).
2. `handleLikeTapped()` → `toggleLike` flips `isLiked`; the displayed count is
   `likeCount + (isLiked ? 1 : 0)`.
3. `handleShareTapped` → emits `.share`.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

The catalog is a static `Component.POSTS` (5 posts) + `comments` (3 sample
comments, 1 nested) built in `ILPostUseCaseImpl`. Like state is in-memory; the
composer bar is UI-only; `.share` is a TODO. Completing these is `tasks.md`
Phases 3–4.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `post` / `Component.POSTS`. See `InnerLamp/Presentation/Scenes/Post/
README.md` for the full design-vs-implementation comparison and changelog.
