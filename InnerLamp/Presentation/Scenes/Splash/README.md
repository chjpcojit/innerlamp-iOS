# Splash

First screen the app shows — pure branding (lamp ignition animation, no loading indicator, no user
interaction). Auto-advances after 3.2s: to `Main` when a Keychain session exists, to `SignUp` when
there is none but onboarding was completed, otherwise to `Onboarding`. Owned top-level by `AppCoordinator`. Themed light/dark via the `--il-spl-*` tokens.

Status, layers and flow live in one place each — do not duplicate them here:

- Spec: `Docs/Specs/Splash/` (`SRS.md`, `requirements.md`, `design.md`, `tasks.md`)
- Knowledge: `Docs/Knowledge/features/splash.md`

## Known gaps vs. design

- Splash views (`ILSplashBrandBackdropView`, `ILSplashAmbienceView`, `ILSplashEmberFieldView`,
  `ILSplashWordmarkLabel`) stay in `Views/` instead of `DesignSystem` — similar treatments exist
  elsewhere (e.g. Onboarding intro) but were not deduplicated. Only `ILLampGlowView` and
  `ILFlameView` are shared.
- The `ilword` reveal fakes the CSS blur with a `shadowRadius` ramp (UIKit has no animatable label
  blur), so the wordmark's "focus pull" reads slightly softer than the prototype.
- No UI test.

## Changelog

- 2026-10-10 — removed the pulsing-dots loading indicator (`ILSplashLoadingIndicatorView`) to match
  the design handoff; routing is by stored Keychain session (`hasSession()`), plus `.goToSignup` when onboarded without a session; README slimmed down.
- 2026-09-25 — light mode: themed `--il-spl-*` colors refresh on `traitCollectionDidChange`; added
  `ILLampGlowView.Style.splash`. The static launch screen also follows system light/dark (no app
  theme override can run that early).
- 2026-09-14 — migrated to Combine `Input`/`Output` + `navigationEventPublisher`; `IL` type prefix;
  reuse `ILLampGlowView` instead of inline lamp drawing; added `ILSplashViewModelTests`.
