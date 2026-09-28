# Requirements — Post

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full post detail with static catalog + in-memory like; no
community API, Share not built, comment composer is UI-only
Feature folder: `InnerLamp/Presentation/Scenes/Post/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Post feature.
> It documents the shipped behavior, including the static mock catalog, the
> in-memory like, the unimplemented Share destination, and the UI-only comment
> composer.

## User Story

As a Sangha member, I want to read a fellow practitioner's post with its
community header, body, like count, and threaded comments, so that I can follow
and engage with the community feed.

## Acceptance Criteria (EARS notation)

- WHEN the Post screen loads for a given post id, THE SYSTEM SHALL show the
  community header (name + member count), the post card (author avatar/initials,
  name, relative time · tag, body), the like/comment/share action row, and the
  comments section with threaded replies.
- WHEN the user taps "Tán thán" (like), THE SYSTEM SHALL toggle the like state
  and update the like count display accordingly.
- WHEN the user taps "Chia sẻ" (share), THE SYSTEM SHALL emit a share event.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Post screen
  and return to Sangha.

## Out of scope (this feature boundary, not backend work)

- The Share screen itself (`.share` reaches a TODO in the coordinator).
- Comment submission — the composer bar is UI-only; the send button has no
  action.
- Per-comment like / reply actions — the prototype attaches no handler, so
  "Tán thán N" / "Trả lời" on individual comments are static.

## Pending (not yet implemented — see `tasks.md`)

- A real community API. `ILPostUseCaseImpl` builds a static 5-post catalog +
  3 comments with a TODO to replace with `NetworkService`. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the posts/comments API contract(s) — no community endpoint
  > in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- Like persistence / submission — `toggleLike` only flips the in-memory
  `isLiked` flag.

- Comment submission — the composer bar renders but does nothing.

- Author avatar tones are **approximate** — derived deterministically from the
  author name (`tone(for:)`) rather than from real author data.

- Visual QA (scroll layout, composer bar, dark mode) not verified on device.

## Open questions (resolved during implementation)

- ~~Is the post's like count display the raw count plus the user's like?~~ →
  Yes — the display count is `likeCount + (isLiked ? 1 : 0)`, reflecting the
  in-memory toggle on top of the catalog count. Resolved during implementation
  (see `ILPostViewModel.makeStateModel`).
