# Changelog — Main Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Main tab-bar
  shell (4 tabs — Home, Library, Sangha, Me — plus a central lamp action).
- `requirements.md`: user story and 5 EARS acceptance criteria (present the
  4-tab shell after auth, switch tabs and sync highlight, lamp button opens
  meditation setup, crossfade on tab switch, hide/show bottom bar). "Pending"
  is empty; two resolved open questions (lamp is an action not a tab;
  `ILTabPlaceholderViewController` is now unused).
- `design.md`: Layers & components table (coordinator, tab bar controller, the
  unused placeholder), the tab-wiring table mapping each `ILBottomNavBar.Tab`
  to its coordinator and feature spec, and the navigation flow. Notes Main
  owns no Domain/Data layer and has no network or Step-by-step Flow.
- `tasks.md`: Phases 1–2 checked (`[x]`); Phase 3 "not applicable"; Phase 4
  leaves deleting the placeholder and the OKF concepts as `[ ]`.
- Reason: Main was one of the implemented features with no spec folder; written
  to close documentation debt, matching the `Docs/Specs/SignUp/` example.
