# Requirements — Sangha

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full tab UI with mock data; no community API, and
find-sangha / sit-together / compose destinations are not built
Feature folder: `InnerLamp/Presentation/Scenes/Sangha/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Sangha
> feature. It documents the shipped behavior, including the static mock data
> and the unimplemented destinations.

## User Story

As a Sangha member, I want a hub that shows a live group-sitting count, my
community, and my fellow practitioners' posts, so that I can stay connected and
engaged with the community.

## Acceptance Criteria (EARS notation)

- WHEN the Sangha tab loads, THE SYSTEM SHALL show a pinned title with a "Tìm
  đạo tràng" link, a live "Đang cùng ngồi thiền" card (participant count +
  "Ngồi cùng" CTA), two quick-action chips (write a post / events & courses),
  the user's own community card with its latest announcement, and a feed of
  posts.
- WHEN the user taps a post card, THE SYSTEM SHALL open the Post screen for
  that post.
- WHEN the user taps the "Sự kiện & khóa học" chip, THE SYSTEM SHALL open the
  Events screen.
- WHEN the user taps the "Đạo tràng của tôi" community card, THE SYSTEM SHALL
  open the Temple screen for that community.
- WHEN the user taps "Tìm đạo tràng" (find sangha), "Ngồi cùng" (sit together),
  or the "Viết bài chia sẻ" (compose) chip, THE SYSTEM SHALL emit the
  corresponding navigation event.

## Out of scope (this feature boundary, not backend work)

- The Post, Events, and Temple screens — owned by their own features (the wired
  destinations).

## Pending (not yet implemented — see `tasks.md`)

- A real community API. `ILSanghaUseCaseImpl.getSangha()` returns static mock
  data (live count, community, one post) with a TODO to replace with
  `NetworkService`. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the sangha/community API contract(s) — no community
  > endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- Three unimplemented destinations: `.openFindSangha`, `.startSitting`, and
  `.openCompose` are TODOs in the coordinator.

- Real-time live count — the participant count is a static snapshot; no
  polling/socket.

- Post engagement ("Tùy hỷ" / "Hồi âm") is display-only — no like/reply action.

- Loading / error / offline states not rendered (`.failure` is a TODO branch).

## Open questions (resolved during implementation)

- ~~Where does tapping a community card navigate?~~ → To the Temple screen
  (`ILTempleCoordinator`) via `showTemple(id:)` — the community card is treated
  as a temple page entry point. Resolved during implementation (see
  `ILSanghaCoordinator`).
