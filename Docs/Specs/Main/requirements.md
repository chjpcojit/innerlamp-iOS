# Requirements — Main

Version: 1.0
Last updated: 2026-09-27
Status: implemented — 4-tab shell with a central lamp action; no network
Feature folder: `InnerLamp/Presentation/Scenes/Main/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Main tab-bar
> shell. Main is a container/coordinator feature, not a single screen: it owns
> no Entity/UseCase/ViewModel/StateModel.

## User Story

As a signed-in user, I want a bottom tab bar to move between the app's main
sections (Home, Library, Sangha, Me), plus a prominent central lamp button to
start a meditation, so that I can navigate the app quickly after login.

## Acceptance Criteria (EARS notation)

- WHEN the user finishes login / registration / onboarding (or enters as a
  guest), THE SYSTEM SHALL present the Main tab-bar shell with four tabs in
  order: Home, Library, Sangha, Me.
- WHEN the user taps a tab, THE SYSTEM SHALL switch to that tab and update the
  bottom bar's active highlight to match.
- WHEN the user taps the central lamp button, THE SYSTEM SHALL present the
  meditation-setup screen as a full-screen modal.
- WHEN a tab is switched, THE SYSTEM SHALL crossfade between tab content (the
  `BaseTabBarController` default transition).
- WHEN a child screen inside a tab needs the bottom bar hidden (e.g. a full-
  screen overlay), THE SYSTEM SHALL support hiding/showing the bottom bar.

## Out of scope (this feature boundary, not backend work)

- The actual content of each tab — Home, Library, Sangha, and Profile are each
  owned by their own feature (and spec).
- The meditation-setup flow itself — owned by the MeditationSetup feature.

## Pending (not yet implemented)

- None. All four tabs are wired to real coordinators; no placeholder remains in
  use (see the resolved open question below).

## Open questions (resolved during implementation)

- ~~Is the central lamp button a fifth tab or an action?~~ → An action, not a
  tab. `.lamp` is deliberately absent from `ILMainTabBarController.tabOrder`;
  tapping it fires `onLampTapped` → `showMeditationSetup()`. Resolved during
  implementation (see `ILMainTabBarController`).
- ~~Do Sangha and Me still use `ILTabPlaceholderViewController`?~~ → No. Both
  were replaced by real coordinators (`makeSanghaCoordinator`,
  `makeProfileCoordinator`); the placeholder file is now unused by any tab and
  can be deleted (noted in `Profile/README.md`). Resolved during
  implementation.
