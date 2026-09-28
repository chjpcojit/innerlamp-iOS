# Changelog — Onboarding Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in
this folder. All three files share one changelog since they change together as
one spec unit. Newest version first.

## v1.0 (initial)

- Initial spec written retroactively from the already-implemented Onboarding
  feature (full 3-step flow, local `UserDefaultsService` persistence, no
  network).
- `requirements.md`: user story and 9 EARS acceptance criteria covering first-
  launch routing, load state, step advancement/CTA labels, last-step
  completion, skip, back navigation, chip/bell toggles, swipe-to-change-step,
  and the completion flag. "Pending" is explicitly empty; one resolved open
  question records that preferences are local (no backend).
- `design.md`: Layers & components table (noting the architectural drift that
  `ILOnboardingStateModel` lives in `Domain/Entities/ILOnboardingModel.swift`
  rather than Presentation), navigation flow, step-progression data flow, and
  a "Local persistence (no network)" section enumerating the three
  `UserDefaultsService` keys. No Step-by-step Flow — there are no API calls.
- `tasks.md`: Phases 1–2 and Phase 4's README checked (`[x]`); Phase 3 marked
  "not applicable" (no network); the OKF concept left `[ ]` as a separate
  `il-okf-writer` task.
- Reason: Onboarding was one of the implemented features with no spec folder;
  written to close documentation debt, matching the `Docs/Specs/SignUp/`
  example.
