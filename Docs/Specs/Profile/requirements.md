# Requirements — Profile

Version: 1.5
Last updated: 2026-10-11
Status: in-progress — v1.4 (logout button + confirm popup; no-rebuild re-render);
mock stats; several destinations (awards/reminder/community) are not built
Feature folder: `InnerLamp/Presentation/Scenes/Profile/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Profile
> feature. It documents the shipped behavior, including the static mock data
> and the partially-built destinations.

## User Story

As a signed-in user, I want a profile hub showing my practice stats, journal
heatmap, badges, merit, a way to support the app, and a menu, so that I can
manage my account and navigate to related screens.

> v1.1 (2026-10-10): updated to the new prototype screen `profile`
> (`Docs/innerlamp-project/project/InnerLamp Prototype.dc.html`, "Hồ sơ").
> Supersedes the v1.0 header layout, the "Sen Vàng" upgrade card and the 4-row
> menu.

## Acceptance Criteria (EARS notation)

- WHEN the Profile tab loads, THE SYSTEM SHALL show, top to bottom: a hero
  cover (250pt), an avatar (84pt, initial)
  overlapping the cover's bottom edge beside the name and the "Pháp danh … ·
  Phật tử tại gia" subtitle, a 3-cell stats card (hours / streak / chant count),
  a 12-week journal heatmap (21 columns × 4 rows), a recent-badges row, a merit
  card, an "Ủng hộ InnerLamp" card, a 7-row menu (Sửa hồ sơ, Gia phả dòng họ,
  Tạo gia phả mới, Chuông tỉnh thức, Cài đặt, Thông báo, Chùa tu tập), and a footer with the app
  version and build number.
- WHEN the user scrolls the content up, THE SYSTEM SHALL move the cover image at
  0.45× the scroll speed (parallax) and, once the content has scrolled past
  150pt, fade in a pinned compact bar showing the user's name (fully visible at
  200pt).
- WHEN the user pulls the content down beyond its top, THE SYSTEM SHALL stretch
  the cover image (height grows with the pull, image scales by 1 + pull / 500).
- WHEN the user taps the "Sửa hồ sơ" menu row, THE SYSTEM SHALL open the EditProfile screen.
- WHEN the user taps the heatmap card, THE SYSTEM SHALL open the Stats screen.
- WHEN the user taps the "Cài đặt" row, THE SYSTEM SHALL open the Settings
  screen.
- WHEN the user taps the "Thông báo" row, THE SYSTEM SHALL open the
  Notifications screen.
- WHEN the user taps the "Dấu ấn tu tập", "Công đức đã hồi hướng", "Ủng hộ
  InnerLamp", or "Chuông tỉnh thức" target, THE SYSTEM SHALL emit
  the corresponding navigation event; the "Công đức đã hồi hướng" card opens
  the MeritBook ("Sổ công đức") screen.
- THE SYSTEM SHALL show the "Ủng hộ InnerLamp" card regardless of the user's plan.
- WHEN the user taps the "Gia phả dòng họ" row, THE SYSTEM SHALL open the
  FamilyTree screen.
- WHEN the user taps the "Tạo gia phả mới" row, THE SYSTEM SHALL open the
  FamilyTreeCreate screen.
- WHEN the user taps "Chùa tu tập" (and has a community), THE SYSTEM SHALL
  emit an open-community event carrying the community id.
- THE SYSTEM SHALL render the footer version and build from the app bundle
  (`CFBundleShortVersionString` / `CFBundleVersion`), not from hardcoded text.
- THE SYSTEM SHALL show a full-width "Đăng xuất" button (danger-coloured label,
  52pt, card style) between the menu card and the version footer.
- WHEN the user taps "Đăng xuất", THE SYSTEM SHALL show a confirmation popup
  "Đăng xuất?" / "Bạn có chắc muốn đăng xuất khỏi InnerLamp?" with a "Hủy" cell
  and a destructive "Đăng xuất" cell; a tap on the scrim SHALL behave as "Hủy".
- WHEN the user taps "Hủy" or the scrim, THE SYSTEM SHALL close the popup and
  keep the user signed in.
- WHEN the user confirms, THE SYSTEM SHALL revoke the session on the server
  (`POST /v1/auth/logout`), delete the stored access and refresh tokens, the
  local user, birth profile, memorial cache, lit lamps and chosen temple, and then replace
  the main area with the Login screen.
- IF the revoke call fails (offline, timeout, 5xx), THEN THE SYSTEM SHALL still
  clear the local session and go to Login.
- IF the local session cannot be cleared (Keychain / local store error), THEN THE
  SYSTEM SHALL stay on Profile, show an error toast ("Không thể đăng xuất. Vui
  lòng thử lại.") and re-enable the button.
- WHILE a logout is running, THE SYSTEM SHALL disable the "Đăng xuất" button so
  it cannot be fired twice.
- WHEN the view model emits the same or a partially changed state (e.g. after
  `GET /v1/users/me` answers), THE SYSTEM SHALL repaint only the sections whose
  data changed, without removing and re-creating unchanged cells/cards.

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

- Four unimplemented destinations: `.openAwards`, `.openDonate` (renamed from
  `.openPaywall`), `.openReminder` and `.openCommunity` are TODOs in the
  coordinator. `.openMeritBook` (v1.3, formerly `.openOffering`) opens the
  MeritBook screen (`Docs/Specs/MeritBook/`).

- No avatar photo (initial only); the header role "Phật tử tại gia" is fixed
  copy; no "find a sangha" event when the user has no community.

- Cover image is a static default (a gradient until the photo asset is added; not per-user, not pickable). See `Docs/Tech-Debt/Profile/TD-Profile-001-*`.

  > ⚠️ Not confirmed: where the per-user cover image comes from (user pick vs
  > backend field) — blocks replacing the bundled default; recorded in
  > `Docs/Assumptions/Profile/`.

- The "Gia phả dòng họ" row's trailing value ("Họ Nguyễn Hữu" in the prototype)
  has no data source on this screen; the row shows no value until the family
  tree name is available to Profile.

  > ⚠️ Not confirmed: which family-tree name the Profile row shows (and its
  > source) — blocks the row's trailing value.

- Loading / error / offline states not rendered.

## Open questions (resolved during implementation)

- ~~Are `editProfile` and `openStats` wired?~~ → Yes. The README's nav-events
  table marks them "TODO", but the coordinator wires `.editProfile` →
  `showEditProfile()` (EditProfile) and `.openStats` → `showStats()` (Stats).
  Resolved 2026-09-27 by reading the coordinator while writing this spec.
- ~~Cover image source?~~ → Static default for now (no photo asset exists yet, so a gradient). Resolved
  2026-10-10 (user decision); per-user source remains ⚠️ above.
- ~~Is the donate card plan-gated, and where does it go?~~ → Always shown;
  emits `.openDonate` (destination TODO). Resolved 2026-10-10 (user decision).
- ~~Where do "Tạo gia phả mới" and "Sổ công đức" go?~~ → FamilyTreeCreate, and
  a TODO `.openMeritBook` event. Resolved 2026-10-10 (user decision).
  **Superseded 2026-10-11:** the prototype dropped the "Sổ công đức" row, so the
  row and `.openMeritBook` are removed.
- ~~Footer version source?~~ → App bundle. Resolved 2026-10-10 (user decision).
