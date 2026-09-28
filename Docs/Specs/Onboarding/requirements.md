# Requirements — Onboarding

Version: 1.0
Last updated: 2026-09-27
Status: implemented — full 3-step flow with local preference persistence; no
network involved
Feature folder: `InnerLamp/Presentation/Scenes/Onboarding/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Onboarding
> feature. It documents the shipped behavior; the feature is complete end to
> end (no stub, no pending API).

## User Story

As a first-time user, I want to be walked through my practice intentions and
bell-reminder preferences, so that the app is set up to feel personal from the
first launch.

## Acceptance Criteria (EARS notation)

- WHEN the app launches for the first time (onboarding not yet completed), THE
  SYSTEM SHALL show a 3-step onboarding flow (intro → practice intents →
  bell reminders) owned by `AppCoordinator`.
- WHEN the onboarding screen loads, THE SYSTEM SHALL show the intro step
  (step 0), with the primary CTA reading "Bắt đầu" and the back/footer label
  reading "Tôi đã có tài khoản", and a step progress bar with three segments.
- WHEN the user taps the primary CTA on a non-last step, THE SYSTEM SHALL
  advance to the next step; the CTA SHALL read "Tiếp tục" on step 1 and "Tạo
  tài khoản" on the last step, and the back label SHALL read "Quay lại" on
  non-first steps.
- WHEN the user taps the primary CTA on the last step, THE SYSTEM SHALL
  persist the selected intents and enabled bells, mark onboarding as completed,
  and navigate to the SignUp screen.
- WHEN the user taps "Bỏ qua" (skip) at any step, THE SYSTEM SHALL persist the
  current preferences, mark onboarding as completed, and navigate to SignUp.
- WHEN the user taps the back control on a non-first step, THE SYSTEM SHALL
  return to the previous step; WHEN the user taps it on the first step, THE
  SYSTEM SHALL navigate to the Login screen.
- WHEN the user taps a practice-intent chip, THE SYSTEM SHALL toggle that
  intent's selection; WHEN the user taps a bell toggle, THE SYSTEM SHALL
  toggle that bell's enabled state.
- WHEN the user swipes horizontally on a step, THE SYSTEM SHALL crossfade to
  the adjacent step, tracking the finger, and commit the step change if the
  swipe passes a threshold.
- WHEN onboarding completes, THE SYSTEM SHALL record the completion flag so
  that subsequent launches skip onboarding and go straight to the main flow.

## Out of scope (this feature boundary, not backend work)

- Account creation and the subsequent OTP verification — owned by SignUp and
  Otp features.
- Syncing the selected intents/bells to a backend. Preferences are stored
  locally via `UserDefaultsService`; there is no server call.

## Pending (not yet implemented)

- None. The feature is fully implemented end to end (see `tasks.md`).

## Open questions (resolved during implementation)

- ~~Does onboarding need a network call to save preferences?~~ → No. The
  selected intents and enabled bells are persisted locally via
  `UserDefaultsService` (`onboarding_selected_intents`,
  `onboarding_enabled_bells`, `has_completed_onboarding`). There is no backend
  involvement. Resolved during implementation (see
  `Presentation/Scenes/Onboarding/README.md`).
