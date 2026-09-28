# Requirements — MeditationSession

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — immersive sitting screen with countdown + breath guidance;
`recordSession` is a stub, and the Done screen is not built
Feature folder: `InnerLamp/Presentation/Scenes/MeditationSession/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented
> MeditationSession feature. It documents the shipped behavior, including the
> stubbed `recordSession` and the unimplemented Done destination.

## User Story

As a practitioner, I want an immersive sitting screen with a countdown, breathing
guidance, and start/end bells, so that I can complete a guided or silent
meditation session.

## Acceptance Criteria (EARS notation)

- WHEN the session screen opens (from MeditationSetup), THE SYSTEM SHALL start a
  running countdown of the selected duration, play an opening bell, and show a
  breathing ring (4s inhale / 6s exhale).
- WHEN the session is guided, THE SYSTEM SHALL show a Vietnamese breath cue with
  its English line, synchronized to the inhale/exhale phase; WHEN it is silent,
  THE SYSTEM SHALL show no cue text.
- WHEN the user taps pause/resume, THE SYSTEM SHALL pause or resume the
  countdown and update the transport icon.
- WHEN the user taps the end control or "Kết thúc sớm", THE SYSTEM SHALL stop
  the session, play a closing bell, and emit a finished event with the elapsed
  seconds.
- WHEN the countdown reaches zero, THE SYSTEM SHALL stop the session, play a
  closing bell, and emit a finished event with the full duration.
- WHEN the user taps the back control, THE SYSTEM SHALL leave the session and
  return to MeditationSetup.

## Out of scope (this feature boundary, not backend work)

- The Done ("Hoàn thành") / Journal screen — not built; on finish, the parent
  (`ILMeditationSetupCoordinator`) currently dismisses the practice-flow modal.

## Pending (not yet implemented — see `tasks.md`)

- `recordSession` — the finished sit is **not** persisted to the practice log
  (streak, weekly minutes, practice mix); `ILMeditationSessionUseCaseImpl.
  recordSession` is a `print("TODO: …")` stub.

  > ⚠️ Not confirmed: the practice-log storage (local Core Data/UserDefaults vs
  > a backend metrics API) — blocks the real `recordSession` implementation.

- The Done screen (the `.finished` event reaches a `print` TODO in
  `ILMeditationSetupCoordinator`).

- Bells are single strikes — the design's "3 tiếng khánh" and the "every 5
  minutes" interval bell (from MeditationSetup) are not scheduled; no voice
  guidance / background-sound audio.

- The countdown is foreground-only (main-run-loop `Timer`); background/locked
  time is not counted.

## Open questions (resolved during implementation)

- ~~Does the session make a network call?~~ → No. The entire session is local;
  the only outbound action is `recordSession` (a stub awaiting a practice-log
  Repository). Resolved during implementation (see
  `Domain/UseCases/MeditationSession/ILMeditationSessionUseCase.swift`).
