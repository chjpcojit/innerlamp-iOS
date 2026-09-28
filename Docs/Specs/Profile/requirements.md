# Requirements — Profile

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full tab UI with mock data; no profile API, and several
destinations (awards/offering/paywall/reminder/community) are not built
Feature folder: `InnerLamp/Presentation/Scenes/Profile/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Profile
> feature. It documents the shipped behavior, including the static mock data
> and the partially-built destinations.

## User Story

As a signed-in user, I want a profile hub showing my practice stats, journal
heatmap, badges, merit, plan, and a menu, so that I can manage my account and
navigate to related screens.

## Acceptance Criteria (EARS notation)

- WHEN the Profile tab loads, THE SYSTEM SHALL show a header (avatar initial,
  name, "Pháp danh … · Phật tử tại gia" subtitle, "Sửa hồ sơ" pill), a 3-cell
  stats card (hours / streak / chant count), a 12-week journal heatmap, a
  recent-badges row, a merit card, a "Sen Vàng" upgrade card (free plan only),
  and a 4-row menu (reminder / settings / notifications / my sangha).
- WHEN the user taps "Sửa hồ sơ", THE SYSTEM SHALL open the EditProfile screen.
- WHEN the user taps the heatmap card, THE SYSTEM SHALL open the Stats screen.
- WHEN the user taps the "Cài đặt" row, THE SYSTEM SHALL open the Settings
  screen.
- WHEN the user taps the "Thông báo" row, THE SYSTEM SHALL open the
  Notifications screen.
- WHEN the user taps the "Dấu ấn tu tập", "Công đức đã hồi hướng", "Sen Vàng",
  or "Chuông tỉnh thức" target, THE SYSTEM SHALL emit the corresponding
  navigation event.
- WHEN the user taps "Đạo tràng của tôi" (and has a community), THE SYSTEM SHALL
  emit an open-community event carrying the community id.

## Out of scope (this feature boundary, not backend work)

- The EditProfile, Stats, Settings, and Notifications screens — owned by their
  own features (the wired destinations).

## Pending (not yet implemented — see `tasks.md`)

- A real profile API. `ILProfileUseCaseImpl.getProfile()` returns static mock
  data (name, dharma name, stats, 84-day heatmap, badges, offering counts,
  plan, reminder, community) with a TODO to replace with `ILProfileRepository`
  → `ILUserRepository` + network. (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the profile / stats / badges API contract(s) — no profile
  > endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- Five unimplemented destinations: `.openAwards`, `.openOffering`,
  `.openPaywall`, `.openReminder`, and `.openCommunity` are TODOs in the
  coordinator.

- No avatar photo (initial only); the header role "Phật tử tại gia" is fixed
  copy; no "find a sangha" event when the user has no community.

- Loading / error / offline states not rendered.

## Open questions (resolved during implementation)

- ~~Are `editProfile` and `openStats` wired?~~ → Yes. The README's nav-events
  table marks them "TODO", but the coordinator wires `.editProfile` →
  `showEditProfile()` (EditProfile) and `.openStats` → `showStats()` (Stats).
  Resolved 2026-09-27 by reading the coordinator while writing this spec.
