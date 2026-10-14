# Changelog — Splash Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.6 (2026-10-11)

- `requirements.md`: no session + onboarding completed now routes to SignUp
  (was Login). Failed session refresh still routes to Login.
- `design.md`: `.goToLogin` → `.goToSignup`; coordinator delegate
  `splashDidRequestSignup` → `showSignUp(asRoot: true)` (replaces the stack and
  hides the back button, since nothing is behind it).
- `tasks.md`: routing item and test description updated.
- `SRS.md`: FR-004 and its scenario updated.
- Reason: user decision — Onboarding only on the first launch after install;
  later launches without a session land on SignUp.

## v1.5 (2026-10-10)

- `requirements.md`: the fresh-install ⚠️ is resolved — Onboarding on first
  launch, Login after a lost session. Pending notes the quit-mid-Onboarding
  edge case.
- `design.md`: Known limitations updated to match.
- `tasks.md`: no change needed, verified (behavior already implemented).
- Reason: user confirmed `AS-Splash-001`, which is now `Validated`.

## v1.4 (2026-10-10)

- `requirements.md`: no session + onboarding completed now routes to Login;
  no session + onboarding not completed still routes to Onboarding; failed
  session refresh → Login stated explicitly. The "onboarded but logged out" ⚠️
  moved to resolved; a smaller ⚠️ remains for fresh installs.
- `design.md`: `.goToLogin` added to the nav events, coordinator delegate (3
  methods), diagram and Routing decision.
- `tasks.md`: routing item checked off; ViewModel tests 3 → 4.
- Reason: product answer — "no token or failed refresh → back to Login".
  Assumption `AS-Splash-001` records that first-time users still see Onboarding.

## v1.3 (2026-10-10)

- `requirements.md`: the "session validity" ⚠️ is resolved — expired access
  tokens are intentionally not checked at launch; the first 401 triggers an
  automatic refresh, and a failed refresh sends the user to Login.
- `design.md`: Known limitations rewritten to describe that recovery path.
- `tasks.md`: no change needed, verified (no task depended on this question).
- Reason: user confirmed the intended behavior; verified against
  `AuthSessionRefresher` and `AppCoordinator.handleSessionExpired()`.

## v1.2 (2026-10-10)

- `requirements.md`: replaced the two onboarding-completed routing criteria with
  session-based ones (Keychain access token → Main, none → Onboarding) and added
  criteria for the fresh-install token purge and legacy-credential purge. Pending
  now holds two ⚠️ items (onboarded-but-logged-out users; token expiry unchecked).
  The "flip the hardcoded route" ⚠️ moved to resolved.
- `design.md`: UseCase row gains `hasSession()` and its injected services; the
  "Routing gap" section became "Routing decision" with the 3-step `hasSession()`
  behavior and Known limitations; navigation diagram no longer says "unused".
- `tasks.md`: routing item checked off; test count 2 → 3; new `[x]` item for the existing
  `ILSplashUseCaseTests` (4 tests), new `[ ]` item (onboarded-but-logged-out
  routing); OKF item checked.
- Reason: code had moved past the spec — routing was no longer hardcoded and the
  UseCase gained Keychain/UserDefaults logic. Retroactive sync from the real
  code. `SRS.md` was synced the same day (v0.2, via ba-writer);
  `Presentation/Scenes/Splash/README.md` was slimmed to an overview + known gaps + changelog (status/flow now live only in the spec and OKF).

## v1.1 (2026-10-10)

- Removed the pulsing-dots loading indicator from the Splash screen (matches the
  design handoff, which has no loading indicator). `requirements.md`, `SRS.md`,
  `design.md`, `tasks.md` updated; `ILSplashLoadingIndicatorView` deleted.
  `ILLoadingDotsView` stays as a shared component.

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
