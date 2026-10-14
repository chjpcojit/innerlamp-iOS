# Changelog — Profile Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.5 — 2026-10-11

- Reason: backend confirmed `GET /v1/users/me` returns `data.full_name` (absent for accounts
  created before it became required).
- Header name is now the full name; falls back to the account email when absent.
  `AS-Profile-002` -> Invalidated. `ILUserMeDTO` / `ILAccountProfileEntity` gained `fullName`.

## v1.4 — 2026-10-11

- Reason: the design prototype's `profile` screen has a "Đăng xuất" button and a
  confirmation popup (`loOpen` / `loShow`); and a flash was reported when scrolling
  up then down right after first entering the screen.
- `requirements.md`: logout button, confirmation popup, confirm / cancel / failure
  behaviour, button disabled while running; repaint only changed sections.
- `design.md`: `logout()` on the use case, `ILLogoutRepository` + `LogoutEndpoint`
  (`POST /v1/auth/logout`), `ILProfileNavEvent.loggedOut`, `ILAlert.confirm`
  popup, `onLogout` closure chain to `AppCoordinator`, logout Step-by-step Flow.
- `tasks.md`: Phase 2c added. Two entries recorded: `AS-Profile-003`, `TD-Profile-004`.
- Backend contract confirmed 2026-10-11 (BE session, verified against its code): no `X-API-Key`
  from mobile; refresh token revoked server-side; the old access token stays valid until its
  15-minute `exp` (no denylist), so the client only drops it locally; an expired access token
  needs refresh-then-retry; no per-device (push/attestation) cleanup; no rate limit on logout.
- Local clearing on sign-out: tokens (Keychain), `User`, `UserBirthProfile`, `Memorial`, `Lamp`
  (Core Data) and the chosen-temple UserDefaults keys. Lamps are mock data (owner decision);
  `LightLamp` spec updated (FR-014).

## v1.3 — 2026-10-11

- Reason: the merit card ("Công đức đã hồi hướng") now opens the new MeritBook screen.
- `ILProfileNavEvent.openOffering` renamed `.openMeritBook`; Input `offeringTapped`
  renamed `meritTapped`. The Offering (donation) flow is a separate, unbuilt feature.
- `requirements.md` / `design.md` / `tasks.md` updated to match.

## v1.2 — 2026-10-11

- Reason: the design prototype's `profile` screen moved "Sửa hồ sơ" from a pill on
  the cover into the menu card and dropped the "Sổ công đức" row
  (`Docs/innerlamp-project/`); added the `user` glyph to `IL-Icon`.
- `requirements.md`: cover has no edit pill; menu is now Sửa hồ sơ, Gia phả
  dòng họ, Tạo gia phả mới, Chuông tỉnh thức, Cài đặt, Thông báo, Chùa tu tập;
  `.openMeritBook` removed.
- `design.md`: header view loses the pill / `onEditTapped`; menu card gains
  `editProfileRow` (`row_user`, new `ILIcons.rowUser`); `ILProfileNavEvent` 11 → 10
  cases; `meritBookTapped` Input removed.
- `tasks.md`: menu / header items updated; merit-book screen task removed.
- Merit card restyled to the prototype (feat gradient/border, 44pt rose `lamp` tile) — `ILProfileMeritCardView` only.

## v1.1 — 2026-10-10

- Reason: the design prototype's `profile` screen was redesigned
  (`Docs/innerlamp-project/`); the shipped screen no longer matched it.
- `requirements.md`: header is now a 250pt cover with edit pill, 84pt
  overlapping avatar and a scroll-driven compact name bar (parallax / stretch
  rules added); "Sen Vàng" upgrade card (free-only) replaced by an
  always-visible "Ủng hộ InnerLamp" card; menu 4 → 7 rows (adds Gia phả dòng
  họ, Tạo gia phả mới, Sổ công đức; "Đạo tràng của tôi" → "Chùa tu tập");
  version footer from bundle; heatmap 21 × 4. Two new ⚠️ (per-user cover
  source; family-tree row value). Four open questions resolved by user
  decision.
- `design.md`: layers table updated (ViewModel events 9 → 11, new compact bar /
  version footer / donate card views, `ILSettingRow` optional icon, new icon +
  cover assets), navigation flow adds `.createFamilyTree`, new "Header &
  scroll behaviour" section.
- `tasks.md`: new Phase 2b for the redesign (all `[ ]`); Phase 4 swaps the
  paywall item for donate + merit book + per-user cover.
- Implemented the same day: Phase 2b checked off except the cover photo asset
  (no photo available → gradient placeholder, TD-Profile-001); unit tests
  written but not executed (test build blocked by the GRPC plug-in).
- Not changed: `Domain/Entities/ILProfileEntity` and the UseCase (still mock);
  Phase 3 API tasks still blocked on the contract.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Profile
  feature (full tab UI with mock data; destinations partially built).
- `requirements.md`: user story and 7 EARS acceptance criteria (load header +
  stats + heatmap + badges + merit + plan + menu, edit profile, open stats, open
  settings, open notifications, emit the five unimplemented events, open
  community). "Pending" records the mock data (with a ⚠️ on the profile API),
  the five TODO destinations, and the missing avatar/role/find-sangha. One
  resolved open question (`editProfile` and `openStats` are wired — the README's
  "TODO" notes for them are stale).
- `design.md`: Layers & components table (Entity + 6 sub-entities/enums, UseCase,
  StateModel, ViewModel, Coordinator, ViewController, 7 feature views, 2 shared
  components), navigation flow (owned by `ILMainTabCoordinator`), data flow, and
  a "Deliberately mock / stub" section. No Step-by-step Flow — no network.
- `tasks.md`: Phases 1–2 checked (`[x]`), reflecting the shipped UI/logic and 18
  tests; Phase 3 (profile API) pending on contract; Phase 4 (unbuilt
  destinations) pending; Phase 5's OKF concept left `[ ]`.
- Reason: Profile was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.

## v1.1 — 2026-10-11
- Integrated `GET /v1/users/me` (account fields only): `UserMeEndpoint`, `ILUserMeDTO`,
  `ILAccountProfileRepository(Impl)`, `ILProfileUseCase.loadProfile()`; the ViewModel overlays
  the server name/dharma name after `viewDidLoad`. Contract confirmed by the backend session:
  Bearer token, no `X-API-Key`, optional keys absent, `401 UNAUTHORIZED` (refresh retried by
  `NetworkService`), `429 RATE_LIMITED` per account.
- Header name = email (AS-Profile-002). Stats/badges/plan stay mock; remaining work in TD-Profile-003.
