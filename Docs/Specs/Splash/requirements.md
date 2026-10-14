# Requirements — Splash

Version: 1.6
Last updated: 2026-10-11
Status: implemented — branding animation and session-based routing done
Feature folder: `InnerLamp/Presentation/Scenes/Splash/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Splash
> feature. It documents the shipped behavior, including the Keychain
> session-based post-splash route (v1.2).

## User Story

As a user opening the app, I want to see a brief branded splash with the lamp
ignition animation, so that the app feels polished while it determines whether
to send me to onboarding or straight into the main experience.

## Acceptance Criteria (EARS notation)

- WHEN the app launches, THE SYSTEM SHALL show the Splash screen first (before
  any other screen), owned by `AppCoordinator`.
- WHEN the Splash screen appears, THE SYSTEM SHALL run the branding animation
  (backdrop glow, ambience ripple/rays, lamp ignite + flicker, ember field,
  wordmark reveal, tagline rise) without any user interaction.
- WHEN the splash animation has played long enough, THE SYSTEM SHALL auto-
  advance to the next screen.
- WHEN the splash auto-advances AND no access token is stored in the Keychain
  AND onboarding has been completed, THE SYSTEM SHALL route to SignUp.
- WHEN the splash auto-advances AND no access token is stored in the Keychain
  AND onboarding has not been completed, THE SYSTEM SHALL route to Onboarding.
- WHEN a request is rejected and the session cannot be refreshed, THE SYSTEM
  SHALL clear the session and route to Login (owned by the networking layer, see
  `AuthSessionRefresher`).
- WHEN the splash auto-advances AND an access token is stored in the Keychain,
  THE SYSTEM SHALL route to the main app (Main).
- WHEN the splash decides its route AND the app has not launched before on this
  install (no `has_launched_before` flag in UserDefaults), THE SYSTEM SHALL first
  delete any Keychain access/refresh tokens left over from a previous install
  and then set the flag.
- WHEN the splash decides its route, THE SYSTEM SHALL delete the legacy
  `signup_pending_credentials` Keychain item if it exists.
- WHEN the light/dark appearance changes, THE SYSTEM SHALL re-resolve the
  themed splash colors (backdrop, glow, ripple, rays, wordmark, tagline) from
  the `--il-spl-*` token family.

## Out of scope (this feature boundary, not backend work)

- Onboarding itself, and the Main app — owned by the Onboarding and Main
  features.

## Pending (not yet implemented — see `tasks.md`)

- A user who quits before finishing Onboarding sees it again on the next
  launch, because the route keys on the "onboarding completed" flag, not on
  "has launched before". Accepted for now (`AS-Splash-001`).

## Open questions (resolved during implementation)

- ~~Does a fresh install with no token see Onboarding or Login?~~ → Onboarding
  on the first launch after install, never afterwards; losing the session sends
  the user to SignUp. Confirmed by the user, 2026-10-10; SignUp (not Login) per user, 2026-10-11 (`AS-Splash-001`
  validated).

- ~~Where should a user with no stored session go if they already completed
  onboarding?~~ → SignUp (changed from Login by the user, 2026-10-11). Implemented as
  `.goToSignup`. A failed session refresh still routes to Login (owned by `AppCoordinator`).

- ~~Should launch validate/refresh the token before routing to Main?~~ → No.
  Splash routes on token **existence** only; an expired access token still
  lands on Main, and the first authenticated request that gets a 401 triggers
  an automatic refresh (`AuthSessionRefresher`). If the refresh fails, the
  session is cleared and the user is sent to Login. Confirmed by the user and
  verified in code, 2026-10-10.

- ~~When to flip the post-splash route off the hardcoded Onboarding?~~ → Routing
  is now decided by a stored Keychain session (`ILSplashUseCase.hasSession()`),
  not by `isOnboardingCompleted()`: session → Main, no session → Onboarding.
  Found already implemented in code and unit-tested; the date of the product
  decision was not recorded. Spec synced 2026-10-10.

- ~~Where does the splash get its "already onboarded?" signal?~~ → From
  `ILOnboardingUseCase.isOnboardingCompleted()`, delegated by
  `ILSplashUseCaseImpl` to avoid duplicating the `has_completed_onboarding`
  key. **Superseded in v1.2:** the method still exists on the UseCase but no
  longer drives the route.
- ~~Does Splash need a dynamic state model?~~ → No. `ILSplashStateModel` is an
  empty marker struct; Splash renders only static branding and has no dynamic
  content. Resolved during implementation.
