# Changelog — Splash Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Splash
  feature (branding animation done; post-splash route temporarily hardcoded to
  Onboarding).
- `requirements.md`: user story and 6 EARS acceptance criteria (show first,
  run branding animation, auto-advance, route to Onboarding when not
  completed, route to Main when completed, re-resolve themed colors). "Pending"
  records the commented-out `isOnboardingCompleted()` branch with a ⚠️ on when
  to flip it. Two resolved open questions (the "already onboarded?" signal
  comes from `ILOnboardingUseCase`; Splash needs no dynamic state).
- `design.md`: Layers & components table (noting the Domain-layer
  `ILSplashStateModel` drift), navigation flow, auto-advance data flow, a
  "Routing gap" section showing the `TEMP DEBUG — revert` code, and the design
  reference. No Step-by-step Flow (no network).
- `tasks.md`: Phase 1 checked (`[x]`), Phase 2 checked except the re-enable-
  routing item (`[ ]`), Phase 3 "not applicable", Phase 4 README checked with
  the OKF concept left `[ ]`.
- Reason: Splash was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
