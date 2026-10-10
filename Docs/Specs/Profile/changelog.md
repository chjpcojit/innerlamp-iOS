# Changelog — Profile Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

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
