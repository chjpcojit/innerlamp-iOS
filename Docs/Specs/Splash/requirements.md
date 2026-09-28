# Requirements — Splash

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — branding animation done; the post-splash route is
temporarily hardcoded to Onboarding (the `isOnboardingCompleted()` branch is
commented out)
Feature folder: `InnerLamp/Presentation/Scenes/Splash/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Splash
> feature. It documents the shipped behavior, including the temporarily
> hardcoded post-splash route.

## User Story

As a user opening the app, I want to see a brief branded splash with the lamp
ignition animation, so that the app feels polished while it determines whether
to send me to onboarding or straight into the main experience.

## Acceptance Criteria (EARS notation)

- WHEN the app launches, THE SYSTEM SHALL show the Splash screen first (before
  any other screen), owned by `AppCoordinator`.
- WHEN the Splash screen appears, THE SYSTEM SHALL run the branding animation
  (backdrop glow, ambience ripple/rays, lamp ignite + flicker, ember field,
  wordmark reveal, tagline rise, pulsing dots) without any user interaction.
- WHEN the splash animation has played long enough, THE SYSTEM SHALL auto-
  advance to the next screen.
- WHEN onboarding has not been completed, THE SYSTEM SHALL route to Onboarding.
- WHEN onboarding has already been completed, THE SYSTEM SHALL route to the
  main app (Main).
- WHEN the light/dark appearance changes, THE SYSTEM SHALL re-resolve the
  themed splash colors (backdrop, glow, ripple, rays, wordmark, tagline) from
  the `--il-spl-*` token family.

## Out of scope (this feature boundary, not backend work)

- Onboarding itself, and the Main app — owned by the Onboarding and Main
  features.

## Pending (not yet implemented — see `tasks.md`)

- The real post-splash routing decision. `ILSplashViewModel.handleSplashFinished()`
  currently **always** emits `.goToOnboarding`; the `useCase.isOnboardingCompleted()`
  branch (which would emit `.goToMain` when onboarding is done) is written but
  **commented out** with a "TEMP DEBUG — revert" marker.

  > ⚠️ Not confirmed: when to flip the branch to use `isOnboardingCompleted()`
  > — it is a product decision (always route through Onboarding during current
  > development vs. skip to Main for already-onboarded users), not something to
  > silently change. Blocks `tasks.md` Phase 2's routing item.

## Open questions (resolved during implementation)

- ~~Where does the splash get its "already onboarded?" signal?~~ → From
  `ILOnboardingUseCase.isOnboardingCompleted()`. `ILSplashUseCaseImpl`
  delegates to `ILOnboardingUseCase` (injected) rather than reading
  UserDefaults directly, to avoid duplicating the `has_completed_onboarding`
  key. Resolved during implementation (see
  `Presentation/Scenes/Splash/README.md`).
- ~~Does Splash need a dynamic state model?~~ → No. `ILSplashStateModel` is an
  empty marker struct; Splash renders only static branding and has no dynamic
  content. Resolved during implementation.
