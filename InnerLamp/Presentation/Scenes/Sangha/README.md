# Sangha

## Overview

Sangha tab ("Đạo tràng"): pinned title with a "Tìm đạo tràng" link, a live "Đang cùng ngồi thiền"
card (participant count + "Ngồi cùng" CTA), two quick-action chips (write a post / events &
courses), the user's own sangha card with its latest announcement, and a feed of fellow
practitioners' posts.
Tab 3 of `ILMainTabBarController` (owned by `ILMainTabCoordinator`; switching tabs is handled by
the tab bar, not by this screen). Design: prototype screen `sangha`
(`Docs/design_handoff_innerlamp/`). No spec under `Docs/Specs/Sangha/` yet.

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILSanghaEntity.swift` | Done | Live session, community, post. Pure business fields (no formatted strings). |
| Presentation — StateModel | `ILSanghaStateModel.swift` | Done | Formatted count / caption / meta / engagement text, optional sections. |
| Data — DTO + Mapper | — | N/A (no confirmed API contract yet) | No sangha endpoint confirmed. |
| Domain — UseCase | `ILSanghaUseCase.swift` | Skeleton | `getSangha()` returns a static mock (TODO: repository → network). |
| Presentation — ViewModel | `ILSanghaViewModel.swift` | Done | 7 Inputs, Entity → StateModel mapping, count / relative-time / initial formatting. |
| Presentation — ViewController | `ILSanghaViewController.swift` | Done | Built from `ILTabHeaderView`, `ILChip`, `ILSectionHeaderView`, `ILAvatarView`, `ILButton` (shared) + `Views/`. Visual QA pending. |
| Presentation — Coordinator | `ILSanghaCoordinator.swift` | Partial | `openEvents` / `openCommunity` / `openPost` wired; `openFindSangha` / `startSitting` / `openCompose` still TODO. |
| Tests | `ILSanghaViewModelTests.swift` | Done | 1 test per Input + state mapping + formatting helpers. |
| Wiring | `DIContainer` + `ILMainTabCoordinator` | Done | Replaces the Sangha tab's `ILTabPlaceholderViewController`. |

## Navigation events

- `openFindSangha` — header "Tìm đạo tràng" tapped. TODO (Temple screen `temple` not built).
- `startSitting` — "Ngồi cùng" tapped. TODO (Setup / Lamp flow `setup` not built).
- `openCompose` — "Viết bài chia sẻ" chip tapped. TODO (`compose` modal not built).
- `openEvents` — "Sự kiện & khóa học" chip tapped. Wired → `showEvents` (`ILEventsCoordinator`).
- `openCommunity(id:)` — "Đạo tràng của tôi" card tapped. Wired → `showTemple` (`ILTempleCoordinator`).
- `openPost(id:)` — post card tapped. Wired → `showPost` (`ILPostCoordinator`).

## Known gaps / not implemented yet

- All data is mock (`ILSanghaUseCaseImpl.getSangha()`) — live count, community and feed need API contracts.
- Live count is a static snapshot; real-time updates (polling / socket) not designed.
- Avatar stack in the live card is decorative (3 tint circles), matching the prototype — no participant data.
- "Ngồi cùng" uses `ILButton` (50pt tall); prototype pill is 44pt and has no shadow.
- Only 1 post is mocked; "Tùy hỷ" / "Hồi âm" are display-only (no like / reply action yet).
- Loading / error / offline states not rendered (`.failure` is a TODO branch).
- Lamp (centre bar button) / Me tabs still unbuilt.

## Changelog

- 2026-09-26 — wired `openPost(id:)` → `ILPostCoordinator` (screen `post`); aligned mock post id to
  `post-2` so the feed tap resolves to the Post catalog.
- 2026-09-20 — initial implementation from design handoff prototype screen `sangha` (il-screen-builder). Added shared `ILTabHeaderView`, `ILColors.tint/tint2/tint3` (+ assets), `ILColors.goldCardBorder`, `ILTypography.note/bodyCompact/statNumber/chevron/quoteItalic`.
